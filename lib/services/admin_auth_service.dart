import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_telemetry_service.dart';
import 'input_security_service.dart';
import 'rate_limit_service.dart';
import 'supabase_service.dart';

class AdminAuthService extends ChangeNotifier {
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

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final normalizedEmail = InputSecurityService.sanitizeEmail(email);

    try {
      if (!InputSecurityService.isValidEmail(normalizedEmail)) {
        _errorMessage = 'Enter a valid admin email address.';
        return false;
      }
      final decision =
          await RateLimitService.beforeAttempt('admin:$normalizedEmail');
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
            'Admin access is not enabled for this account yet. Add this user to platform_admins in Supabase to use the live admin console.';
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
    _adminEntry = await SupabaseService.getPlatformAdminEntry();
  }

  String _friendlyAdminError(Object error) {
    final message = error.toString();
    final lowered = message.toLowerCase();
    if (lowered.contains('invalid login credentials')) {
      return 'The admin email or password is incorrect for live Supabase access. Use the configured owner credentials or create this admin user in Supabase Authentication.';
    }
    return 'The admin app could not complete sign in. $message';
  }
}
