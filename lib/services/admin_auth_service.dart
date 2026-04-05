import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    try {
      await SupabaseService.signIn(email.trim().toLowerCase(), password);
      _currentUser = SupabaseService.currentUser;
      await _refreshAdminAccess();
      if (!isAdmin) {
        _errorMessage =
            'This account is not listed in platform_admins yet. Add it in Supabase before using the admin app.';
        return false;
      }
      return true;
    } catch (error) {
      _errorMessage = 'Could not sign in. ${error.toString()}';
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
    await SupabaseService.signOut();
    _currentUser = null;
    _adminEntry = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _refreshAdminAccess() async {
    _adminEntry = await SupabaseService.getPlatformAdminEntry();
  }
}
