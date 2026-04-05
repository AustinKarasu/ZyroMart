import 'package:flutter/material.dart';
import '../models/user.dart';
import 'mock_data.dart';
import 'supabase_service.dart';

class AuthService extends ChangeNotifier {
  AppUser? _currentUser;
  UserRole? _selectedRole;
  bool _isLoading = false;
  bool _otpRequested = false;
  String? _pendingPhone;
  String? _pendingEmail;
  String? _pendingName;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  UserRole? get selectedRole => _selectedRole;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get otpRequested => _otpRequested;
  String? get pendingPhone => _pendingPhone;
  String? get pendingEmail => _pendingEmail;
  String? get errorMessage => _errorMessage;
  bool get canUseSupabaseAuth => SupabaseService.isInitialized;

  Future<void> initialize() async {
    if (!SupabaseService.isInitialized) {
      return;
    }

    final sessionUser = SupabaseService.currentUser;
    if (sessionUser == null) {
      return;
    }

    final role = _selectedRole ?? _inferRoleFromEmail(sessionUser.email ?? '');
    _currentUser = _buildUser(
      email: sessionUser.email ?? _fallbackEmailForPhone(sessionUser.phone ?? '+910000000000'),
      phone: sessionUser.phone ?? MockData.defaultCustomer.phone,
      name: sessionUser.userMetadata?['name']?.toString(),
      role: role,
    );
    _selectedRole = role;
    notifyListeners();
  }

  void selectRole(UserRole role) {
    _selectedRole = role;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> requestOtp({
    required String phone,
    String? email,
    required String name,
    required UserRole role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedRole = role;
    _pendingPhone = _normalizePhone(phone);
    _pendingEmail = email?.trim().toLowerCase();
    _pendingName = name.trim();
    notifyListeners();

    try {
      if (_pendingPhone == null) {
        _errorMessage = 'Enter a valid phone number with country code.';
        return false;
      }
      if (canUseSupabaseAuth) {
        await SupabaseService.requestPhoneOtp(
          phone: _pendingPhone!,
          email: _pendingEmail,
          userName: _pendingName!,
          role: role.name,
        );
      }
      _otpRequested = true;
      return true;
    } catch (error) {
      _errorMessage = 'Could not send OTP. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String otpCode) async {
    if (_pendingPhone == null || _selectedRole == null) {
      _errorMessage = 'Start the login flow again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (canUseSupabaseAuth) {
        await SupabaseService.verifyPhoneOtp(
          phone: _pendingPhone!,
          otpCode: otpCode.trim(),
        );
      } else if (otpCode.trim() != '123456') {
        _errorMessage = 'Use 123456 in demo mode.';
        return false;
      }

      _currentUser = _buildUser(
        email: _pendingEmail ?? _fallbackEmailForPhone(_pendingPhone!),
        phone: _pendingPhone!,
        name: _pendingName,
        role: _selectedRole!,
      );
      _otpRequested = false;
      return true;
    } catch (error) {
      _errorMessage = 'Invalid or expired OTP. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (canUseSupabaseAuth) {
      await SupabaseService.signOut();
    }
    _currentUser = null;
    _selectedRole = null;
    _otpRequested = false;
    _pendingPhone = null;
    _pendingEmail = null;
    _pendingName = null;
    _errorMessage = null;
    notifyListeners();
  }

  AppUser _buildUser({
    required String email,
    required String phone,
    String? name,
    required UserRole role,
  }) {
    switch (role) {
      case UserRole.customer:
        return MockData.defaultCustomer.copyWith(
          email: email,
          phone: phone,
          name: name,
        );
      case UserRole.storeOwner:
        return MockData.defaultStoreOwner.copyWith(
          email: email,
          phone: phone,
          name: name,
        );
      case UserRole.delivery:
        return MockData.deliveryPersons.first.copyWith(
          email: email,
          phone: phone,
          name: name,
        );
    }
  }

  UserRole _inferRoleFromEmail(String email) {
    if (email.contains('delivery') || email.contains('rider')) {
      return UserRole.delivery;
    }
    if (email.contains('store') || email.contains('owner')) {
      return UserRole.storeOwner;
    }
    return UserRole.customer;
  }

  String? _normalizePhone(String input) {
    final trimmed = input.trim().replaceAll(' ', '');
    if (trimmed.length < 10) {
      return null;
    }

    if (trimmed.startsWith('+')) {
      return trimmed;
    }

    if (trimmed.length == 10) {
      return '+91$trimmed';
    }

    return '+$trimmed';
  }

  String _fallbackEmailForPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return 'user$digits@zyromart.app';
  }
}
