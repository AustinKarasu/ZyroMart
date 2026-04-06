import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class AdminPreferencesScreen extends StatefulWidget {
  const AdminPreferencesScreen({super.key});

  @override
  State<AdminPreferencesScreen> createState() => _AdminPreferencesScreenState();
}

class _AdminPreferencesScreenState extends State<AdminPreferencesScreen> {
  bool _isLoading = true;
  bool _highlightCancelled = true;
  bool _highlightPayoutDrift = true;
  bool _focusLiveSignals = true;
  String _defaultOpsFocus = 'out_for_delivery';
  int _metricsWindowDays = 7;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _AdminPreferencesRepository.load('admin');
    if (settings.isNotEmpty) {
      _highlightCancelled = settings['highlight_cancelled'] as bool? ?? true;
      _highlightPayoutDrift = settings['highlight_payout_drift'] as bool? ?? true;
      _focusLiveSignals = settings['focus_live_signals'] as bool? ?? true;
      _defaultOpsFocus = (settings['default_ops_focus'] ?? _defaultOpsFocus).toString();
      _metricsWindowDays = settings['metrics_window_days'] as int? ?? 7;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _persist() async {
    await _AdminPreferencesRepository.save(
      'admin',
      {
        'highlight_cancelled': _highlightCancelled,
        'highlight_payout_drift': _highlightPayoutDrift,
        'focus_live_signals': _focusLiveSignals,
        'default_ops_focus': _defaultOpsFocus,
        'metrics_window_days': _metricsWindowDays,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin preferences')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AdminCard(
                  title: 'Operational emphasis',
                  subtitle: 'Tune what the admin app should surface first when watching the platform.',
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Highlight cancelled orders'),
                        subtitle: const Text('Keep cancellation-heavy behavior visually prominent in the control room.'),
                        value: _highlightCancelled,
                        onChanged: (value) => setState(() => _highlightCancelled = value),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Highlight payout drift'),
                        subtitle: const Text('Call out larger held-vs-released payout gaps.'),
                        value: _highlightPayoutDrift,
                        onChanged: (value) => setState(() => _highlightPayoutDrift = value),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Focus live signals'),
                        subtitle: const Text('Keep real-time customer and rider activity front and center.'),
                        value: _focusLiveSignals,
                        onChanged: (value) => setState(() => _focusLiveSignals = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _AdminCard(
                  title: 'Dashboard defaults',
                  subtitle: 'Choose how the control room should bias operational monitoring for this admin account.',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _defaultOpsFocus,
                        decoration: const InputDecoration(labelText: 'Default operations focus'),
                        items: const [
                          DropdownMenuItem(value: 'placed', child: Text('Placed orders')),
                          DropdownMenuItem(value: 'preparing', child: Text('Preparing orders')),
                          DropdownMenuItem(value: 'out_for_delivery', child: Text('Out for delivery')),
                          DropdownMenuItem(value: 'cancelled', child: Text('Cancelled orders')),
                        ],
                        onChanged: (value) => setState(() => _defaultOpsFocus = value ?? 'out_for_delivery'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Metrics history window',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text('$_metricsWindowDays days', style: const TextStyle(color: AppTheme.textMedium)),
                        ],
                      ),
                      Slider(
                        min: 3,
                        max: 30,
                        divisions: 27,
                        value: _metricsWindowDays.toDouble(),
                        onChanged: (value) => setState(() => _metricsWindowDays = value.round()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await _persist();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Admin preferences saved')),
                    );
                  },
                  child: const Text('Save admin preferences'),
                ),
              ],
            ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _AdminCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: AppTheme.textMedium, height: 1.45)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _AdminPreferencesRepository {
  static const _localKey = 'operator::admin::singleton';

  static Future<Map<String, dynamic>> load(String appVariant) async {
    if (SupabaseService.isInitialized) {
      final remote = await SupabaseService.getOperatorPreferences(appVariant: appVariant);
      final settings = remote?['settings'];
      if (settings is Map && settings.isNotEmpty) {
        return Map<String, dynamic>.from(settings);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    if (raw == null) return const {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> save(String appVariant, Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKey, jsonEncode(settings));
    if (SupabaseService.isInitialized) {
      await SupabaseService.upsertOperatorPreferences(
        appVariant: appVariant,
        settings: settings,
      );
    }
  }
}
