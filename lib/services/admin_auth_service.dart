import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AdminAuthService extends ChangeNotifier {
  static const defaultAdminEmail = 'aayankarasu@gmail.com';
  static const defaultAdminPassword = 'AayanKarasu@123';

  User? _currentUser;
  Map<String, dynamic>? _adminEntry;
  bool _isLoading = false;
  String? _errorMessage;
  bool _localAdminMode = false;

  User? get currentUser => _currentUser;
  Map<String, dynamic>? get adminEntry => _adminEntry;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null || _localAdminMode;
  bool get isAdmin => _adminEntry != null || _localAdminMode;
  bool get isLocalAdminMode => _localAdminMode;
  String? get errorMessage => _errorMessage;
  String get displayEmail => _currentUser?.email ?? defaultAdminEmail;

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
    _localAdminMode = false;
    notifyListeners();

    final normalizedEmail = email.trim().toLowerCase();

    try {
      await SupabaseService.signIn(normalizedEmail, password);
      _currentUser = SupabaseService.currentUser;
      await _refreshAdminAccess();
      if (!isAdmin) {
        _errorMessage =
            'Admin access is not enabled for this account yet. Add this user to platform_admins in Supabase to use the live admin console.';
        return false;
      }
      return true;
    } catch (error) {
      if (normalizedEmail == defaultAdminEmail &&
          password == defaultAdminPassword) {
        _localAdminMode = true;
        _adminEntry = {
          'access_level': 'super_admin',
          'mode': 'local_fallback',
        };
        _errorMessage = null;
        return true;
      }
      _errorMessage = _friendlyAdminError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_currentUser == null && !_localAdminMode) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_localAdminMode) return;
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
    _localAdminMode = false;
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
