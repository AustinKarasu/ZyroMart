import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_service.dart';

class AppTelemetryService {
  static Future<void> trackFeatureUse({
    required String eventName,
    required String appVariant,
    Map<String, dynamic>? metadata,
  }) async {
    await _storeEvent(
      type: 'feature',
      payload: {
        'event_name': eventName,
        'app_variant': appVariant,
        'metadata': metadata ?? const <String, dynamic>{},
      },
    );
  }

  static Future<void> trackAuthAttempt({
    required String route,
    required bool success,
    String? identifierHash,
    String appVariant = 'storefront',
  }) async {
    await _storeEvent(
      type: 'auth',
      payload: {
        'event_name': success ? 'auth_success' : 'auth_failure',
        'app_variant': appVariant,
        'metadata': {
          'route': route,
          'identifier_hash': identifierHash,
          'success': success,
        },
      },
    );
  }

  static Future<void> logCrash({
    required Object error,
    StackTrace? stackTrace,
    required String appVariant,
    String source = 'flutter',
  }) async {
    await _storeEvent(
      type: 'crash',
      payload: {
        'app_variant': appVariant,
        'source': source,
        'message': error.toString(),
        'stack_trace': stackTrace?.toString(),
      },
    );
  }

  static Future<void> flush() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? const [];
    if (queue.isEmpty) return;

    final remaining = <String>[];
    for (final entry in queue) {
      final decoded = jsonDecode(entry);
      if (decoded is! Map<String, dynamic>) continue;
      try {
        final type = decoded['type']?.toString();
        final payload = Map<String, dynamic>.from(
          decoded['payload'] as Map? ?? const {},
        );
        switch (type) {
          case 'feature':
          case 'auth':
            await SupabaseService.insertAppUsageEvent(payload);
            break;
          case 'crash':
            await SupabaseService.insertCrashReport(payload);
            break;
          default:
            break;
        }
      } catch (_) {
        remaining.add(entry);
      }
    }
    await prefs.setStringList(_queueKey, remaining);
  }

  static Future<void> _storeEvent({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final event = {
      'type': type,
      'payload': {
        ...payload,
        'created_at': DateTime.now().toIso8601String(),
      },
    };
    if (SupabaseService.isInitialized) {
      try {
        switch (type) {
          case 'feature':
          case 'auth':
            await SupabaseService.insertAppUsageEvent(
              Map<String, dynamic>.from(event['payload']! as Map),
            );
            return;
          case 'crash':
            await SupabaseService.insertCrashReport(
              Map<String, dynamic>.from(event['payload']! as Map),
            );
            return;
        }
      } catch (error) {
        debugPrint('Telemetry queue fallback: $error');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? <String>[];
    queue.add(jsonEncode(event));
    await prefs.setStringList(_queueKey, queue.takeLast(150).toList());
  }

  static const String _queueKey = 'telemetry::queue';
}

extension<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    final list = toList();
    if (list.length <= count) return list;
    return list.sublist(list.length - count);
  }
}
