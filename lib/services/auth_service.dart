import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/user.dart';
import 'app_preferences_service.dart';
import 'mock_data.dart';
import 'supabase_service.dart';

class AuthService extends ChangeNotifier {
  AppUser? _currentUser;
  UserRole? _selectedRole;
  bool _isLoading = false;
  bool _otpRequested = false;
  bool _initialized = false;
  String? _pendingPhone;
  String? _pendingEmail;
  String? _pendingName;
  String? _pendingPassword;
  String? _errorMessage;
  String? _statusMessage;
  bool _isPasswordLogin = false;
  AppPreferencesService? _preferences;

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
    if (_initialized) return;
    _initialized = true;
    if (!SupabaseService.isInitialized) return;
    if (_preferences != null && !_preferences!.autoLogin) {
      await SupabaseService.signOut();
      await _preferences?.setUserScope(null);
      return;
    }
    await _hydrateCurrentUser();
  }

  void applyPreferences(AppPreferencesService preferences) {
    _preferences = preferences;
    preferences.setUserScope(_currentUser?.id);
    if (!_initialized) {
      initialize();
      return;
    }
    if (!preferences.autoLogin && SupabaseService.currentUser != null) {
      logout();
    }
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
    String? password,
    required String name,
    required UserRole role,
  }) async {
    _isLoading = true;
    _clearMessages();
    _selectedRole = role;
    _pendingPhone = _normalizePhone(phone);
    _pendingEmail = email?.trim().toLowerCase();
    _pendingName = name.trim();
    _pendingPassword = password;
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
      if ((_pendingEmail?.isNotEmpty ?? false) &&
          (_pendingPassword?.isNotEmpty ?? false)) {
        await SupabaseService.updateAccount(
          email: _pendingEmail!,
          password: _pendingPassword!,
          data: {
            'name': _pendingName,
            'role': _roleToDb(_selectedRole!),
          },
        );
      }
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
      final profile = await SupabaseService.getMyProfile();
      final actualRole = _roleFromDb(profile?['role']?.toString());
      if (actualRole == null || actualRole != role) {
        await SupabaseService.signOut();
        _errorMessage =
            'This account belongs to ${_roleLabel(actualRole)}. Use the matching role to sign in.';
        return false;
      }
      await _hydrateCurrentUser(
        fallbackRole: role,
        fallbackEmail: email.trim().toLowerCase(),
      );
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
    required String address,
    required String phone,
    required UserRole role,
    String? profileImageUrl,
    LatLng? location,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _clearMessages();
    notifyListeners();

    try {
      await _upsertCurrentProfile(
        role: role,
        phone: _normalizePhone(phone) ?? _currentUser!.phone,
        email: _currentUser!.email,
        name: name.trim(),
        address: address.trim(),
        profileImageUrl: profileImageUrl,
        location: location,
      );
      await _hydrateCurrentUser(
        fallbackRole: role,
        fallbackName: name.trim(),
        fallbackPhone: _normalizePhone(phone) ?? _currentUser!.phone,
        fallbackEmail: _currentUser!.email,
        fallbackLocation: location,
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
    _pendingPassword = null;
    _clearMessages();
    await _preferences?.setUserScope(null);
    notifyListeners();
  }

  Future<void> _hydrateCurrentUser({
    UserRole? fallbackRole,
    String? fallbackName,
    String? fallbackPhone,
    String? fallbackEmail,
    LatLng? fallbackLocation,
  }) async {
    final sessionUser = SupabaseService.currentUser;
    if (sessionUser == null) return;

    final profile = await SupabaseService.getMyProfile();
    final dbRole =
        (profile?['role'] ?? sessionUser.userMetadata?['role'] ?? '').toString();
    final role = _roleFromDb(dbRole.isEmpty ? null : dbRole) ??
        fallbackRole ??
        _inferRoleFromEmail(sessionUser.email ?? fallbackEmail ?? '');

    final phone =
        (profile?['phone'] ?? sessionUser.phone ?? fallbackPhone ?? MockData.defaultCustomer.phone).toString();
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
        ((profile?['latitude'] ?? fallbackLocation?.latitude ?? _fallbackLocation(role).latitude) as num)
            .toDouble(),
        ((profile?['longitude'] ?? fallbackLocation?.longitude ?? _fallbackLocation(role).longitude) as num)
            .toDouble(),
      ),
      profileImageUrl: profile?['profile_image_url']?.toString(),
      deliveryRating: profile?['delivery_rating'] == null
          ? null
          : ((profile?['delivery_rating']) as num).toDouble(),
      completedDeliveries: profile?['completed_deliveries'] as int?,
      isOnline: profile?['is_online'] ?? true,
    );
    _selectedRole = role;
    await _preferences?.setUserScope(_currentUser?.id);
  }

  Future<void> _upsertCurrentProfile({
    required UserRole role,
    required String phone,
    String? email,
    String? name,
    String? address,
    String? profileImageUrl,
    LatLng? location,
  }) async {
    final sessionUser = SupabaseService.currentUser;
    if (sessionUser == null) return;

    final fallback = _fallbackLocation(role);
    await SupabaseService.upsertProfile({
      'id': sessionUser.id,
      'name':
          (name ?? sessionUser.userMetadata?['name'] ?? 'ZyroMart User').toString(),
      'email':
          (email ?? sessionUser.email ?? _fallbackEmailForPhone(phone)).toString(),
      'phone': phone,
      'role': _roleToDb(role),
      'address': address ?? _currentUser?.address ?? '',
      'profile_image_url': profileImageUrl ?? _currentUser?.profileImageUrl,
      'latitude': location?.latitude ?? _currentUser?.location.latitude ?? fallback.latitude,
      'longitude': location?.longitude ?? _currentUser?.location.longitude ?? fallback.longitude,
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

  String _roleLabel(UserRole? role) {
    switch (role) {
      case UserRole.customer:
        return 'customer';
      case UserRole.storeOwner:
        return 'store owner';
      case UserRole.delivery:
        return 'delivery partner';
      case null:
        return 'another role';
    }
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
