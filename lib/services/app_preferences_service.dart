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
    await _loadRemoteSnapshot();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setString(_scopedKey(_themeKey), mode.name);
    await _syncRemoteSnapshot();
    notifyListeners();
  }

  Future<void> setAutoLogin(bool value) async {
    _autoLogin = value;
    await _prefs?.setBool(_scopedKey(_autoLoginKey), value);
    await _syncRemoteSnapshot();
    notifyListeners();
  }

  Future<void> setOrderNotifications(bool value) async {
    _orderNotifications = value;
    await _prefs?.setBool(_scopedKey(_orderNotificationsKey), value);
    await _syncRemoteSnapshot();
    notifyListeners();
  }

  Future<void> setMarketingNotifications(bool value) async {
    _marketingNotifications = value;
    await _prefs?.setBool(_scopedKey(_marketingNotificationsKey), value);
    await _syncRemoteSnapshot();
    notifyListeners();
  }

  Future<void> setHideSensitiveItems(bool value) async {
    _hideSensitiveItems = value;
    await _prefs?.setBool(_scopedKey(_hideSensitiveKey), value);
    await _syncRemoteSnapshot();
    notifyListeners();
  }

  Future<void> setTwoFactorEnabled(bool value) async {
    _twoFactorEnabled = value;
    await _prefs?.setBool(_scopedKey(_twoFactorKey), value);
    await _syncRemoteSnapshot();
    notifyListeners();
  }

  Future<void> setBiometricUnlock(bool value) async {
    _biometricUnlock = value;
    await _prefs?.setBool(_scopedKey(_biometricKey), value);
    await _syncRemoteSnapshot();
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs?.setBool(_scopedKey(_soundEnabledKey), value);
    if (value) {
      SystemSound.play(SystemSoundType.alert);
    }
    await _syncRemoteSnapshot();
    notifyListeners();
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

  Future<void> _loadRemoteSnapshot() async {
    if (_scope == 'guest' || !SupabaseService.isInitialized) return;
    try {
      final remote = await SupabaseService.getUserAccountState();
      final payload = remote?['app_preferences'];
      if (payload is! Map || payload.isEmpty) return;
      final snapshot = Map<String, dynamic>.from(payload);
      _themeMode = _themeModeFromString(snapshot['theme_mode']?.toString());
      _autoLogin = snapshot['auto_login'] as bool? ?? _autoLogin;
      _orderNotifications =
          snapshot['order_notifications'] as bool? ?? _orderNotifications;
      _marketingNotifications =
          snapshot['marketing_notifications'] as bool? ??
          _marketingNotifications;
      _soundEnabled = snapshot['sound_enabled'] as bool? ?? _soundEnabled;
      _hideSensitiveItems =
          snapshot['hide_sensitive_items'] as bool? ?? _hideSensitiveItems;
      _biometricUnlock =
          snapshot['biometric_unlock'] as bool? ?? _biometricUnlock;
      _twoFactorEnabled =
          snapshot['two_factor_enabled'] as bool? ?? _twoFactorEnabled;
      await _persistLocalSnapshot();
    } catch (_) {
      // Keep local cache when remote profile state is unavailable.
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

  Future<void> _syncRemoteSnapshot() async {
    if (_scope == 'guest' || !SupabaseService.isInitialized) return;
    try {
      await SupabaseService.upsertUserAccountState({
        'app_preferences': _snapshot(),
      });
    } catch (_) {
      // Local cache is still persisted above.
    }
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
