import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RateLimitDecision {
  const RateLimitDecision({
    required this.allowed,
    required this.remainingAttempts,
    this.retryAfter,
  });

  final bool allowed;
  final int remainingAttempts;
  final Duration? retryAfter;
}

class RateLimitService {
  static const int maxAttempts = 5;
  static const Duration window = Duration(minutes: 15);

  static Future<RateLimitDecision> beforeAttempt(String bucket) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamps = await _loadBucket(prefs, bucket);
    final now = DateTime.now();
    final active = timestamps
        .where((ts) => now.difference(ts) <= window)
        .toList()
      ..sort();
    await _saveBucket(prefs, bucket, active);
    final remaining = maxAttempts - active.length;
    if (remaining <= 0) {
      final oldest = active.first;
      final retryAfter = window - now.difference(oldest);
      return RateLimitDecision(
        allowed: false,
        remainingAttempts: 0,
        retryAfter: retryAfter.isNegative ? Duration.zero : retryAfter,
      );
    }
    return RateLimitDecision(
      allowed: true,
      remainingAttempts: remaining,
    );
  }

  static Future<void> recordFailure(String bucket) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamps = await _loadBucket(prefs, bucket);
    final now = DateTime.now();
    final active = timestamps
        .where((ts) => now.difference(ts) <= window)
        .toList();
    active.add(now);
    await _saveBucket(prefs, bucket, active);
  }

  static Future<void> clear(String bucket) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(bucket));
  }

  static String formatRetry(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  static Future<List<DateTime>> _loadBucket(
    SharedPreferences prefs,
    String bucket,
  ) async {
    final raw = prefs.getString(_key(bucket));
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .map((entry) => DateTime.tryParse(entry.toString()))
        .whereType<DateTime>()
        .toList();
  }

  static Future<void> _saveBucket(
    SharedPreferences prefs,
    String bucket,
    List<DateTime> timestamps,
  ) async {
    await prefs.setString(
      _key(bucket),
      jsonEncode(timestamps.map((ts) => ts.toIso8601String()).toList()),
    );
  }

  static String _key(String bucket) => 'rate_limit::$bucket';
}
