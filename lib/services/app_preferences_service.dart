import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_service.dart';

class AppPreferencesService extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _autoLoginKey = 'auto_login';
  static const _orderNotificationsKey = 'order_notifications';
  static const _marketingNotificationsKey = 'marketing_notifications';
  static const _soundEnabledKey = 'sound_enabled';
  static const _hideSensitiveKey = 'hide_sensitive';
  static const _biometricKey = 'biometric_enabled';
  static const _twoFactorKey = 'two_factor_enabled';

  SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.light;
  bool _autoLogin = true;
  bool _orderNotifications = true;
  bool _marketingNotifications = true;
  bool _soundEnabled = true;
  bool _hideSensitiveItems = false;
  bool _biometricUnlock = false;
  bool _twoFactorEnabled = true;
  bool _ready = false;
  String _scope = 'guest';
  String? _lastSyncError;
  bool _lastRemoteSyncSucceeded = true;

  ThemeMode get themeMode => _themeMode;
  bool get autoLogin => _autoLogin;
  bool get orderNotifications => _orderNotifications;
  bool get marketingNotifications => _marketingNotifications;
  bool get soundEnabled => _soundEnabled;
  bool get hideSensitiveItems => _hideSensitiveItems;
  bool get biometricUnlock => _biometricUnlock;
  bool get twoFactorEnabled => _twoFactorEnabled;
  bool get ready => _ready;
  String get scope => _scope;
  String? get lastSyncError => _lastSyncError;
  bool get lastRemoteSyncSucceeded => _lastRemoteSyncSucceeded;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadScopedPreferences();
    _ready = true;
    notifyListeners();
  }

  Future<void> setUserScope(String? userId) async {
    final nextScope = (userId == null || userId.isEmpty) ? 'guest' : userId;
    if (_scope == nextScope && _ready) return;
    _scope = nextScope;
    await _loadScopedPreferences();
    if (!_ready) {
      _ready = true;
    }
    notifyListeners();
  }

  Future<void> _loadScopedPreferences() async {
    _themeMode = _themeModeFromString(_prefs?.getString(_scopedKey(_themeKey)));
    _autoLogin = _prefs?.getBool(_scopedKey(_autoLoginKey)) ?? true;
    _orderNotifications =
        _prefs?.getBool(_scopedKey(_orderNotificationsKey)) ?? true;
    _marketingNotifications =
        _prefs?.getBool(_scopedKey(_marketingNotificationsKey)) ?? true;
    _soundEnabled = _prefs?.getBool(_scopedKey(_soundEnabledKey)) ?? true;
    _hideSensitiveItems =
        _prefs?.getBool(_scopedKey(_hideSensitiveKey)) ?? false;
    _biometricUnlock = _prefs?.getBool(_scopedKey(_biometricKey)) ?? false;
    _twoFactorEnabled = _prefs?.getBool(_scopedKey(_twoFactorKey)) ?? true;
    _lastSyncError = null;
    _lastRemoteSyncSucceeded = true;
    await _loadRemoteSnapshot();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _commitChange(() => _themeMode = mode);
  }

  Future<void> setAutoLogin(bool value) async {
    await _commitChange(() => _autoLogin = value);
  }

  Future<void> setOrderNotifications(bool value) async {
    await _commitChange(() => _orderNotifications = value);
  }

  Future<void> setMarketingNotifications(bool value) async {
    await _commitChange(() => _marketingNotifications = value);
  }

  Future<void> setHideSensitiveItems(bool value) async {
    await _commitChange(() => _hideSensitiveItems = value);
  }

  Future<void> setTwoFactorEnabled(bool value) async {
    await _commitChange(() => _twoFactorEnabled = value);
  }

  Future<void> setBiometricUnlock(bool value) async {
    await _commitChange(() => _biometricUnlock = value);
  }

  Future<void> setSoundEnabled(bool value) async {
    await _commitChange(() => _soundEnabled = value, playSystemSound: value);
  }

  String _scopedKey(String key) => '$_scope::$key';

  Map<String, dynamic> _snapshot() {
    return {
      'theme_mode': _themeMode.name,
      'auto_login': _autoLogin,
      'order_notifications': _orderNotifications,
      'marketing_notifications': _marketingNotifications,
      'sound_enabled': _soundEnabled,
      'hide_sensitive_items': _hideSensitiveItems,
      'biometric_unlock': _biometricUnlock,
      'two_factor_enabled': _twoFactorEnabled,
    };
  }

  Map<String, dynamic> _notificationPreferenceSnapshot() {
    return {
      'order_updates': _orderNotifications,
      'marketing_updates': _marketingNotifications,
      'recommendations': _marketingNotifications,
      'account_alerts': true,
      'earnings_alerts': true,
    };
  }

  void _restoreSnapshot(Map<String, dynamic> snapshot) {
    _themeMode = _themeModeFromString(snapshot['theme_mode']?.toString());
    _autoLogin = snapshot['auto_login'] as bool? ?? true;
    _orderNotifications = snapshot['order_notifications'] as bool? ?? true;
    _marketingNotifications =
        snapshot['marketing_notifications'] as bool? ?? true;
    _soundEnabled = snapshot['sound_enabled'] as bool? ?? true;
    _hideSensitiveItems = snapshot['hide_sensitive_items'] as bool? ?? false;
    _biometricUnlock = snapshot['biometric_unlock'] as bool? ?? false;
    _twoFactorEnabled = snapshot['two_factor_enabled'] as bool? ?? true;
  }

  Future<void> _commitChange(
    VoidCallback applyChange, {
    bool playSystemSound = false,
  }) async {
    final previous = _snapshot();
    applyChange();

    if (_scope == 'guest') {
      await _persistLocalSnapshot();
      if (playSystemSound) {
        SystemSound.play(SystemSoundType.alert);
      }
      _lastSyncError = null;
      _lastRemoteSyncSucceeded = true;
      notifyListeners();
      return;
    }

    try {
      if (!SupabaseService.isInitialized) {
        throw StateError(SupabaseService.backendStatusMessage);
      }
      await Future.wait([
        SupabaseService.upsertUserAccountState({
          'app_preferences': _snapshot(),
        }),
        SupabaseService.upsertNotificationPreferences(
          _notificationPreferenceSnapshot(),
        ),
        SupabaseService.upsertNotificationDevice(
          deviceToken: 'storefront-$_scope-primary',
          platform: 'android',
          appVariant: 'storefront',
          pushEnabled: _orderNotifications || _marketingNotifications,
        ),
      ]);
      await _persistLocalSnapshot();
      if (playSystemSound) {
        SystemSound.play(SystemSoundType.alert);
      }
      _lastSyncError = null;
      _lastRemoteSyncSucceeded = true;
    } catch (error) {
      _restoreSnapshot(previous);
      _lastSyncError = 'Could not save settings to the backend. $error';
      _lastRemoteSyncSucceeded = false;
    }
    notifyListeners();
  }

  Future<void> _loadRemoteSnapshot() async {
    if (_scope == 'guest' || !SupabaseService.isInitialized) return;
    try {
      final remoteState = await SupabaseService.getUserAccountState();
      final notificationPreferences =
          await SupabaseService.getNotificationPreferences();
      final payload = remoteState?['app_preferences'];
      if (payload is Map && payload.isNotEmpty) {
        _restoreSnapshot(Map<String, dynamic>.from(payload));
      }
      if (notificationPreferences != null) {
        _orderNotifications =
            notificationPreferences['order_updates'] ?? _orderNotifications;
        _marketingNotifications =
            notificationPreferences['marketing_updates'] ??
            _marketingNotifications;
      }
      await _persistLocalSnapshot();
      _lastSyncError = null;
      _lastRemoteSyncSucceeded = true;
    } catch (error) {
      _lastSyncError = 'Could not load settings from the backend. $error';
      _lastRemoteSyncSucceeded = false;
    }
  }

  Future<void> _persistLocalSnapshot() async {
    await _prefs?.setString(_scopedKey(_themeKey), _themeMode.name);
    await _prefs?.setBool(_scopedKey(_autoLoginKey), _autoLogin);
    await _prefs?.setBool(
      _scopedKey(_orderNotificationsKey),
      _orderNotifications,
    );
    await _prefs?.setBool(
      _scopedKey(_marketingNotificationsKey),
      _marketingNotifications,
    );
    await _prefs?.setBool(_scopedKey(_soundEnabledKey), _soundEnabled);
    await _prefs?.setBool(_scopedKey(_hideSensitiveKey), _hideSensitiveItems);
    await _prefs?.setBool(_scopedKey(_biometricKey), _biometricUnlock);
    await _prefs?.setBool(_scopedKey(_twoFactorKey), _twoFactorEnabled);
  }

  ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }
}
