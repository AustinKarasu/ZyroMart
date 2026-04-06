import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_telemetry_service.dart';
import 'input_security_service.dart';
import 'rate_limit_service.dart';
import 'supabase_service.dart';

class AdminAuthService extends ChangeNotifier {
  static const Set<String> _ownerAllowlist = {'aayankarasu@gmail.com'};

  User? _currentUser;
  Map<String, dynamic>? _adminEntry;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  Map<String, dynamic>? get adminEntry => _adminEntry;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _adminEntry != null;
  String? get errorMessage => _errorMessage;
  String get displayEmail => _currentUser?.email ?? 'admin@zyromart';

  Future<void> initialize() async {
    if (!SupabaseService.isInitialized) return;
    _currentUser = SupabaseService.currentUser;
    if (_currentUser != null) {
      await _refreshAdminAccess();
    }
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final normalizedEmail = InputSecurityService.sanitizeEmail(email);

    try {
      if (!SupabaseService.isInitialized) {
        _errorMessage =
            'Admin backend is not initialized in this build. Reinstall the latest app with valid Supabase configuration.';
        return false;
      }
      if (!InputSecurityService.isValidEmail(normalizedEmail)) {
        _errorMessage = 'Enter a valid admin email address.';
        return false;
      }
      final decision = await RateLimitService.beforeAttempt(
        'admin:$normalizedEmail',
      );
      if (!decision.allowed) {
        _errorMessage =
            'Too many admin sign-in attempts. Try again in ${RateLimitService.formatRetry(decision.retryAfter!)}.';
        return false;
      }
      await SupabaseService.signIn(normalizedEmail, password);
      _currentUser = SupabaseService.currentUser;
      await _refreshAdminAccess();
      if (!isAdmin) {
        _errorMessage =
            'This account is not authorized for admin access.';
        await RateLimitService.recordFailure('admin:$normalizedEmail');
        return false;
      }
      await RateLimitService.clear('admin:$normalizedEmail');
      await AppTelemetryService.trackAuthAttempt(
        route: 'admin_sign_in',
        success: true,
        identifierHash: normalizedEmail.hashCode.toString(),
        appVariant: 'admin',
      );
      return true;
    } catch (error) {
      await RateLimitService.recordFailure('admin:$normalizedEmail');
      await AppTelemetryService.trackAuthAttempt(
        route: 'admin_sign_in',
        success: false,
        identifierHash: normalizedEmail.hashCode.toString(),
        appVariant: 'admin',
      );
      _errorMessage = _friendlyAdminError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_currentUser == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _refreshAdminAccess();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_currentUser != null) {
      await SupabaseService.signOut();
    }
    _currentUser = null;
    _adminEntry = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _refreshAdminAccess() async {
    if (_currentUser == null) {
      _adminEntry = null;
      return;
    }
    final email = (_currentUser!.email ?? '').trim().toLowerCase();
    if (_ownerAllowlist.contains(email)) {
      _adminEntry = const {
        'access_level': 'owner',
        'source': 'allowlist',
      };
      return;
    }
    try {
      _adminEntry = await SupabaseService.getPlatformAdminEntry();
    } catch (_) {
      _adminEntry = null;
    }
  }

  String _friendlyAdminError(Object error) {
    final message = error.toString();
    final lowered = message.toLowerCase();
    if (lowered.contains('invalid login credentials')) {
      return 'The admin email or password is incorrect. Please verify your credentials and try again.';
    }
    if (lowered.contains('platform_admins') ||
        lowered.contains('infinite recursion') ||
        lowered.contains('42p17')) {
      return 'Admin verification is currently unavailable from the database policy layer. Use owner credentials or update admin policies and retry.';
    }
    return 'The admin app could not complete sign in right now. Please try again shortly.';
  }
}
