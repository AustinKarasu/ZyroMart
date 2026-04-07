import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_service.dart';

class OperatorPreferencesService {
  static String _localKey(String userId, String appVariant) =>
      'operator::$appVariant::$userId';

  static Future<Map<String, dynamic>> load({
    required String appVariant,
    required String userId,
  }) async {
    try {
      if (SupabaseService.isInitialized) {
        final remote = await SupabaseService.getOperatorPreferences(
          appVariant: appVariant,
        );
        final settings = remote?['settings'];
        if (settings is Map && settings.isNotEmpty) {
          return Map<String, dynamic>.from(settings);
        }
      }
    } catch (_) {
      // Fall back to local cache when the remote settings fetch fails.
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey(userId, appVariant));
    if (raw == null) return const {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> save({
    required String appVariant,
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    if (!SupabaseService.isInitialized) {
      throw StateError(SupabaseService.backendStatusMessage);
    }
    await SupabaseService.upsertOperatorPreferences(
      appVariant: appVariant,
      settings: settings,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKey(userId, appVariant), jsonEncode(settings));
  }
}
