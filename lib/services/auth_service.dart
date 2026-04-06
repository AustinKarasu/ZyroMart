import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/user.dart';
import 'app_preferences_service.dart';
import 'app_telemetry_service.dart';
import 'input_security_service.dart';
import 'rate_limit_service.dart';
import 'supabase_service.dart';

class AuthService extends ChangeNotifier {
  AppUser? _currentUser;
  UserRole? _selectedRole;
  UserRole? _sessionRoleOverride;
  bool _isLoading = false;
  bool _otpRequested = false;
  bool _initialized = false;
  String? _pendingPhone;
  String? _pendingEmail;
  String? _pendingName;
  String? _pendingPassword;
  String? _pendingStoreName;
  String? _pendingStoreAddress;
  LatLng? _pendingStoreLocation;
  String? _errorMessage;
  String? _statusMessage;
  bool _isPasswordLogin = false;
  bool _pendingIsSignUpFlow = false;
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
    bool isSignUpFlow = false,
    String? storeName,
    String? storeAddress,
    LatLng? storeLocation,
  }) async {
    _isLoading = true;
    _clearMessages();
    _selectedRole = role;
    _pendingPhone = _normalizePhone(phone);
    _pendingEmail = email?.trim().toLowerCase();
    _pendingName = name.trim();
    _pendingPassword = password;
    _pendingStoreName = storeName?.trim();
    _pendingStoreAddress = storeAddress?.trim();
    _pendingStoreLocation = storeLocation;
    _pendingIsSignUpFlow = isSignUpFlow;
    notifyListeners();

    try {
      if (_pendingPhone == null) {
        _errorMessage = 'Enter a valid phone number with country code.';
        return false;
      }
      if (_pendingName != null &&
          _pendingName!.length > InputSecurityService.nameMaxLength) {
        _errorMessage = 'Name is too long.';
        return false;
      }
      if (isSignUpFlow && (_pendingName == null || _pendingName!.isEmpty)) {
        _errorMessage = 'Enter your full name for signup.';
        return false;
      }
      if (isSignUpFlow && role == UserRole.storeOwner) {
        if ((_pendingStoreName ?? '').isEmpty) {
          _errorMessage = 'Store name is required for store owner signup.';
          return false;
        }
        if ((_pendingStoreAddress ?? '').isEmpty) {
          _errorMessage = 'Store location is required for store owner signup.';
          return false;
        }
      }
      if (_pendingEmail != null &&
          !InputSecurityService.isValidEmail(_pendingEmail!)) {
        _errorMessage = 'Enter a valid email address.';
        return false;
      }
      final decision = await RateLimitService.beforeAttempt(
        'otp:${_pendingPhone!}',
      );
      if (!decision.allowed) {
        _errorMessage =
            'Too many OTP attempts. Try again in ${RateLimitService.formatRetry(decision.retryAfter!)}.';
        return false;
      }
      if (!canUseSupabaseAuth) {
        _errorMessage = 'Supabase auth is not configured.';
        return false;
      }

      await SupabaseService.requestPhoneOtp(
        phone: _pendingPhone!,
        email: _pendingEmail,
        userName: (_pendingName ?? '').isEmpty
            ? 'ZyroMart User'
            : _pendingName!,
        role: _roleToDb(role),
      );
      await RateLimitService.clear('otp:${_pendingPhone!}');
      await AppTelemetryService.trackAuthAttempt(
        route: 'phone_otp_request',
        success: true,
        identifierHash: _pendingPhone!.hashCode.toString(),
      );

      _statusMessage = 'OTP sent to $_pendingPhone';
      _otpRequested = true;
      return true;
    } catch (error) {
      await RateLimitService.recordFailure('otp:${_pendingPhone!}');
      await AppTelemetryService.trackAuthAttempt(
        route: 'phone_otp_request',
        success: false,
        identifierHash: _pendingPhone!.hashCode.toString(),
      );
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
      final existingProfile = await SupabaseService.getMyProfile();
      final existingRole = _roleFromDb(existingProfile?['role']?.toString());
      final selectedRole = _selectedRole!;
      final effectiveRole = _pendingIsSignUpFlow
          ? (existingRole ?? selectedRole)
          : selectedRole;
      if (!_pendingIsSignUpFlow) {
        _sessionRoleOverride = selectedRole;
      }
      await _upsertCurrentProfile(
        role: existingRole ?? effectiveRole,
        phone: _pendingPhone!,
        email: _pendingEmail,
        name: _pendingName,
        address: effectiveRole == UserRole.storeOwner
            ? _pendingStoreAddress
            : null,
        location: effectiveRole == UserRole.storeOwner
            ? _pendingStoreLocation
            : null,
      );
      if ((_pendingEmail?.isNotEmpty ?? false) &&
          (_pendingPassword?.isNotEmpty ?? false)) {
        await SupabaseService.updateAccount(
          email: _pendingEmail!,
          password: _pendingPassword!,
          data: {'name': _pendingName, 'role': _roleToDb(effectiveRole)},
        );
      }
      await _upsertOwnerStoreIfNeeded(role: effectiveRole);
      await _hydrateCurrentUser(
        fallbackRole: effectiveRole,
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
    _sessionRoleOverride = role;
    notifyListeners();

    try {
      if (!canUseSupabaseAuth) {
        _errorMessage = 'Supabase auth is not configured.';
        return false;
      }
      final normalizedEmail = InputSecurityService.sanitizeEmail(email);
      if (!InputSecurityService.isValidEmail(normalizedEmail)) {
        _errorMessage = 'Enter a valid email address.';
        return false;
      }
      final decision = await RateLimitService.beforeAttempt(
        'password:$normalizedEmail',
      );
      if (!decision.allowed) {
        _errorMessage =
            'Too many sign-in attempts. Try again in ${RateLimitService.formatRetry(decision.retryAfter!)}.';
        return false;
      }
      await SupabaseService.signIn(normalizedEmail, password);
      await RateLimitService.clear('password:$normalizedEmail');
      await AppTelemetryService.trackAuthAttempt(
        route: 'password_sign_in',
        success: true,
        identifierHash: normalizedEmail.hashCode.toString(),
      );
      await _hydrateCurrentUser(fallbackEmail: normalizedEmail);
      _statusMessage = 'Signed in successfully';
      return true;
    } catch (error) {
      final normalizedEmail = InputSecurityService.sanitizeEmail(email);
      await RateLimitService.recordFailure('password:$normalizedEmail');
      await AppTelemetryService.trackAuthAttempt(
        route: 'password_sign_in',
        success: false,
        identifierHash: normalizedEmail.hashCode.toString(),
      );
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
      _statusMessage =
          'Email and password updated. You can now use password login.';
      return true;
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('email_exists') ||
          message.contains('already been registered') ||
          message.contains('already registered')) {
        _errorMessage =
            'This email is already linked with another account. Use a different email or sign in directly with that email.';
      } else if (message.contains('invalid email')) {
        _errorMessage = 'Enter a valid email address.';
      } else if (message.contains('password')) {
        _errorMessage = 'Password does not meet security requirements.';
      } else {
        _errorMessage = 'Could not save password login. Please try again.';
      }
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

  Future<bool> setOnlineStatus(bool isOnline) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    _clearMessages();
    notifyListeners();
    try {
      await _upsertCurrentProfile(
        role: _currentUser!.role,
        phone: _currentUser!.phone,
        email: _currentUser!.email,
        name: _currentUser!.name,
        address: _currentUser!.address,
        profileImageUrl: _currentUser!.profileImageUrl,
        location: _currentUser!.location,
        isOnline: isOnline,
      );
      _currentUser = _currentUser!.copyWith(isOnline: isOnline);
      _statusMessage = isOnline ? 'You are online' : 'You are offline';
      return true;
    } catch (error) {
      _errorMessage = 'Could not update availability. ${error.toString()}';
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
    _sessionRoleOverride = null;
    _otpRequested = false;
    _pendingPhone = null;
    _pendingEmail = null;
    _pendingName = null;
    _pendingPassword = null;
    _pendingStoreName = null;
    _pendingStoreAddress = null;
    _pendingStoreLocation = null;
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
    final dbRole = (profile?['role'] ?? sessionUser.userMetadata?['role'] ?? '')
        .toString();
    final role =
        _sessionRoleOverride ??
        _roleFromDb(dbRole.isEmpty ? null : dbRole) ??
        fallbackRole ??
        _inferRoleFromEmail(sessionUser.email ?? fallbackEmail ?? '');

    final phone =
        (profile?['phone'] ?? sessionUser.phone ?? fallbackPhone ?? '')
            .toString();
    final email =
        (profile?['email'] ??
                sessionUser.email ??
                fallbackEmail ??
                _fallbackEmailForPhone(phone))
            .toString();

    _currentUser = AppUser(
      id: sessionUser.id,
      name:
          (profile?['name'] ??
                  sessionUser.userMetadata?['name'] ??
                  fallbackName ??
                  'ZyroMart User')
              .toString(),
      email: email,
      phone: phone,
      role: role,
      address: (profile?['address'] ?? '').toString(),
      location: LatLng(
        ((profile?['latitude'] ??
                    fallbackLocation?.latitude ??
                    _fallbackLocation(role).latitude)
                as num)
            .toDouble(),
        ((profile?['longitude'] ??
                    fallbackLocation?.longitude ??
                    _fallbackLocation(role).longitude)
                as num)
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
    bool? isOnline,
  }) async {
    final sessionUser = SupabaseService.currentUser;
    if (sessionUser == null) return;

    final fallback = _fallbackLocation(role);
    await SupabaseService.upsertProfile({
      'id': sessionUser.id,
      'name': InputSecurityService.sanitizePlainText(
        (name ?? sessionUser.userMetadata?['name'] ?? 'ZyroMart User')
            .toString(),
        maxLength: InputSecurityService.nameMaxLength,
      ),
      'email': (email ?? sessionUser.email ?? _fallbackEmailForPhone(phone))
          .toString(),
      'phone': phone,
      'role': _roleToDb(role),
      'address': InputSecurityService.sanitizePlainText(
        address ?? _currentUser?.address ?? '',
        maxLength: InputSecurityService.addressMaxLength,
        allowNewLines: true,
      ),
      'profile_image_url': profileImageUrl ?? _currentUser?.profileImageUrl,
      'latitude':
          location?.latitude ??
          _currentUser?.location.latitude ??
          fallback.latitude,
      'longitude':
          location?.longitude ??
          _currentUser?.location.longitude ??
          fallback.longitude,
      'is_online': isOnline ?? _currentUser?.isOnline ?? true,
    });
  }

  Future<void> _upsertOwnerStoreIfNeeded({required UserRole role}) async {
    if (role != UserRole.storeOwner) return;
    final sessionUser = SupabaseService.currentUser;
    if (sessionUser == null) return;
    final storeName = (_pendingStoreName ?? '').trim();
    final storeAddress = (_pendingStoreAddress ?? '').trim();
    if (storeName.isEmpty || storeAddress.isEmpty) return;
    final fallback =
        _pendingStoreLocation ??
        _currentUser?.location ??
        _fallbackLocation(UserRole.storeOwner);
    await SupabaseService.upsertOwnerStore(
      ownerId: sessionUser.id,
      name: InputSecurityService.sanitizePlainText(storeName, maxLength: 90),
      address: InputSecurityService.sanitizePlainText(
        storeAddress,
        maxLength: InputSecurityService.addressMaxLength,
        allowNewLines: true,
      ),
      latitude: fallback.latitude,
      longitude: fallback.longitude,
      phone: _pendingPhone,
    );
  }

  LatLng _fallbackLocation(UserRole role) {
    // Neutral fallback to avoid hardcoded city defaults in production flows.
    return const LatLng(20.5937, 78.9629);
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
    final trimmed =
        InputSecurityService.sanitizePhone(input)?.replaceAll(' ', '') ?? '';
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
    if (lowered.contains('email_exists') ||
        lowered.contains('already been registered') ||
        lowered.contains('already registered')) {
      return 'This email is already linked with another account. Use a different email or sign in directly with that email.';
    }

    return isVerification
        ? 'Could not verify OTP. $message'
        : 'Could not send OTP. $message';
  }
}
