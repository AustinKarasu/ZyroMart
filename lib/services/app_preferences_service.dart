import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  ThemeMode get themeMode => _themeMode;
  bool get autoLogin => _autoLogin;
  bool get orderNotifications => _orderNotifications;
  bool get marketingNotifications => _marketingNotifications;
  bool get soundEnabled => _soundEnabled;
  bool get hideSensitiveItems => _hideSensitiveItems;
  bool get biometricUnlock => _biometricUnlock;
  bool get twoFactorEnabled => _twoFactorEnabled;
  bool get ready => _ready;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _themeMode = _themeModeFromString(_prefs?.getString(_themeKey));
    _autoLogin = _prefs?.getBool(_autoLoginKey) ?? true;
    _orderNotifications = _prefs?.getBool(_orderNotificationsKey) ?? true;
    _marketingNotifications = _prefs?.getBool(_marketingNotificationsKey) ?? true;
    _soundEnabled = _prefs?.getBool(_soundEnabledKey) ?? true;
    _hideSensitiveItems = _prefs?.getBool(_hideSensitiveKey) ?? false;
    _biometricUnlock = _prefs?.getBool(_biometricKey) ?? false;
    _twoFactorEnabled = _prefs?.getBool(_twoFactorKey) ?? true;
    _ready = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setString(_themeKey, mode.name);
    notifyListeners();
  }

  Future<void> setAutoLogin(bool value) async {
    _autoLogin = value;
    await _prefs?.setBool(_autoLoginKey, value);
    notifyListeners();
  }

  Future<void> setOrderNotifications(bool value) async {
    _orderNotifications = value;
    await _prefs?.setBool(_orderNotificationsKey, value);
    notifyListeners();
  }

  Future<void> setMarketingNotifications(bool value) async {
    _marketingNotifications = value;
    await _prefs?.setBool(_marketingNotificationsKey, value);
    notifyListeners();
  }

  Future<void> setHideSensitiveItems(bool value) async {
    _hideSensitiveItems = value;
    await _prefs?.setBool(_hideSensitiveKey, value);
    notifyListeners();
  }

  Future<void> setTwoFactorEnabled(bool value) async {
    _twoFactorEnabled = value;
    await _prefs?.setBool(_twoFactorKey, value);
    notifyListeners();
  }

  Future<void> setBiometricUnlock(bool value) async {
    _biometricUnlock = value;
    await _prefs?.setBool(_biometricKey, value);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs?.setBool(_soundEnabledKey, value);
    if (value) {
      SystemSound.play(SystemSoundType.alert);
    }
    notifyListeners();
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
