import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

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
  String? _statusMessage;
  bool _isPasswordLogin = false;

  AppUser? get currentUser => _currentUser;
  UserRole? get selectedRole => _selectedRole;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get otpRequested => _otpRequested;
  String? get pendingPhone => _pendingPhone;
  String? get pendingEmail => _pendingEmail;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  bool get canUseSupabaseAuth => SupabaseService.isInitialized;
  bool get isPasswordLogin => _isPasswordLogin;

  Future<void> initialize() async {
    if (!SupabaseService.isInitialized) return;
    await _hydrateCurrentUser();
  }

  void selectRole(UserRole role) {
    _selectedRole = role;
    _clearMessages();
    notifyListeners();
  }

  void setPasswordMode(bool value) {
    _isPasswordLogin = value;
    _clearMessages();
    notifyListeners();
  }

  Future<bool> requestOtp({
    required String phone,
    String? email,
    required String name,
    required UserRole role,
  }) async {
    _isLoading = true;
    _clearMessages();
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
      if (!canUseSupabaseAuth) {
        _errorMessage = 'Supabase auth is not configured.';
        return false;
      }

      await SupabaseService.requestPhoneOtp(
        phone: _pendingPhone!,
        email: _pendingEmail,
        userName: _pendingName!.isEmpty ? 'ZyroMart User' : _pendingName!,
        role: _roleToDb(role),
      );

      _statusMessage = 'OTP sent to $_pendingPhone';
      _otpRequested = true;
      return true;
    } catch (error) {
      _errorMessage = _friendlyOtpError(error);
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
    _clearMessages();
    notifyListeners();

    try {
      await SupabaseService.verifyPhoneOtp(
        phone: _pendingPhone!,
        otpCode: otpCode.trim(),
      );
      await _upsertCurrentProfile(
        role: _selectedRole!,
        phone: _pendingPhone!,
        email: _pendingEmail,
        name: _pendingName,
      );
      await _hydrateCurrentUser(
        fallbackRole: _selectedRole,
        fallbackName: _pendingName,
        fallbackPhone: _pendingPhone,
        fallbackEmail: _pendingEmail,
      );
      _otpRequested = false;
      _statusMessage = 'Logged in successfully';
      return true;
    } catch (error) {
      _errorMessage = _friendlyOtpError(error, isVerification: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithPassword({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    _clearMessages();
    _selectedRole = role;
    notifyListeners();

    try {
      await SupabaseService.signIn(email.trim().toLowerCase(), password);
      await _hydrateCurrentUser(fallbackRole: role, fallbackEmail: email.trim().toLowerCase());
      _statusMessage = 'Signed in successfully';
      return true;
    } catch (error) {
      _errorMessage = 'Could not sign in. ${error.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setupEmailPassword({
    required String email,
    required String password,
  }) async {
    if (!canUseSupabaseAuth || SupabaseService.currentUser == null) {
      _errorMessage = 'Log in first before setting email and password.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _clearMessages();
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();
      await SupabaseService.updateAccount(
        email: normalizedEmail,
        password: password,
        data: {
          'name': _currentUser?.name,
          'role': _roleToDb(_currentUser?.role ?? UserRole.customer),
        },
      );
      await _upsertCurrentProfile(
        role: _currentUser?.role ?? UserRole.customer,
        phone: _currentUser?.phone ?? '',
        email: normalizedEmail,
        name: _currentUser?.name,
      );
      await _hydrateCurrentUser(
        fallbackRole: _currentUser?.role,
        fallbackName: _currentUser?.name,
        fallbackPhone: _currentUser?.phone,
        fallbackEmail: normalizedEmail,
      );
      _statusMessage = 'Email and password updated. You can now use password login.';
      return true;
    } catch (error) {
      _errorMessage = 'Could not save password login. ${error.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String address,
    required UserRole role,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _clearMessages();
    notifyListeners();

    try {
      await _upsertCurrentProfile(
        role: role,
        phone: _currentUser!.phone,
        email: email.trim().toLowerCase(),
        name: name.trim(),
        address: address.trim(),
      );
      await _hydrateCurrentUser(
        fallbackRole: role,
        fallbackName: name.trim(),
        fallbackPhone: _currentUser!.phone,
        fallbackEmail: email.trim().toLowerCase(),
      );
      _statusMessage = 'Profile saved';
      return true;
    } catch (error) {
      _errorMessage = 'Could not update profile. ${error.toString()}';
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
    _clearMessages();
    notifyListeners();
  }

  Future<void> _hydrateCurrentUser({
    UserRole? fallbackRole,
    String? fallbackName,
    String? fallbackPhone,
    String? fallbackEmail,
  }) async {
    final sessionUser = SupabaseService.currentUser;
    if (sessionUser == null) return;

    final profile = await SupabaseService.getMyProfile();
    final dbRole = (profile?['role'] ?? sessionUser.userMetadata?['role'] ?? '').toString();
    final role = _roleFromDb(dbRole.isEmpty ? null : dbRole) ??
        fallbackRole ??
        _inferRoleFromEmail(sessionUser.email ?? fallbackEmail ?? '');

    final phone = (profile?['phone'] ?? sessionUser.phone ?? fallbackPhone ?? MockData.defaultCustomer.phone).toString();
    final email = (profile?['email'] ??
            sessionUser.email ??
            fallbackEmail ??
            _fallbackEmailForPhone(phone))
        .toString();

    _currentUser = AppUser(
      id: sessionUser.id,
      name: (profile?['name'] ??
              sessionUser.userMetadata?['name'] ??
              fallbackName ??
              'ZyroMart User')
          .toString(),
      email: email,
      phone: phone,
      role: role,
      address: (profile?['address'] ?? '').toString(),
      location: LatLng(
        ((profile?['latitude'] ?? _fallbackLocation(role).latitude) as num).toDouble(),
        ((profile?['longitude'] ?? _fallbackLocation(role).longitude) as num).toDouble(),
      ),
      profileImageUrl: profile?['profile_image_url']?.toString(),
      deliveryRating: profile?['delivery_rating'] == null
          ? null
          : ((profile?['delivery_rating']) as num).toDouble(),
      completedDeliveries: profile?['completed_deliveries'] as int?,
      isOnline: profile?['is_online'] ?? true,
    );
    _selectedRole = role;
  }

  Future<void> _upsertCurrentProfile({
    required UserRole role,
    required String phone,
    String? email,
    String? name,
    String? address,
  }) async {
    final sessionUser = SupabaseService.currentUser;
    if (sessionUser == null) return;

    final fallback = _fallbackLocation(role);
    await SupabaseService.upsertProfile({
      'id': sessionUser.id,
      'name': (name ?? sessionUser.userMetadata?['name'] ?? 'ZyroMart User').toString(),
      'email': (email ?? sessionUser.email ?? _fallbackEmailForPhone(phone)).toString(),
      'phone': phone,
      'role': _roleToDb(role),
      'address': address ?? _currentUser?.address ?? '',
      'latitude': _currentUser?.location.latitude ?? fallback.latitude,
      'longitude': _currentUser?.location.longitude ?? fallback.longitude,
      'is_online': _currentUser?.isOnline ?? true,
    });
  }

  LatLng _fallbackLocation(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return MockData.defaultCustomer.location;
      case UserRole.storeOwner:
        return MockData.defaultStoreOwner.location;
      case UserRole.delivery:
        return MockData.deliveryPersons.first.location;
    }
  }

  UserRole? _roleFromDb(String? value) {
    switch (value) {
      case 'customer':
        return UserRole.customer;
      case 'store_owner':
        return UserRole.storeOwner;
      case 'delivery':
        return UserRole.delivery;
      default:
        return null;
    }
  }

  String _roleToDb(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'customer';
      case UserRole.storeOwner:
        return 'store_owner';
      case UserRole.delivery:
        return 'delivery';
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
    if (trimmed.length < 10) return null;
    if (trimmed.startsWith('+')) return trimmed;
    if (trimmed.length == 10) return '+91$trimmed';
    return '+$trimmed';
  }

  String _fallbackEmailForPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return 'user$digits@zyromart.app';
  }

  void _clearMessages() {
    _errorMessage = null;
    _statusMessage = null;
  }

  String _friendlyOtpError(Object error, {bool isVerification = false}) {
    final message = error.toString();
    final lowered = message.toLowerCase();

    if (lowered.contains('invalid api key')) {
      return 'Supabase publishable key is invalid. Install the latest app build.';
    }
    if (lowered.contains('sms') &&
        (lowered.contains('not enabled') ||
            lowered.contains('not configured') ||
            lowered.contains('provider'))) {
      return 'Supabase phone auth is not fully configured. Enable Phone and your SMS provider.';
    }
    if (lowered.contains('invalid phone')) {
      return 'Enter a valid phone number in international format, for example +919876543210.';
    }
    if (lowered.contains('expired') || lowered.contains('token')) {
      return isVerification
          ? 'The OTP is invalid or expired. Request a new code and try again.'
          : 'OTP request failed. Please try again.';
    }

    return isVerification
        ? 'Could not verify OTP. $message'
        : 'Could not send OTP. $message';
  }
}
