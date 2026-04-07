import 'package:flutter/material.dart';

import '../../services/operator_preferences_service.dart';
import '../../theme/app_theme.dart';

class StoreOperationsPreferencesScreen extends StatefulWidget {
  final String userId;

  const StoreOperationsPreferencesScreen({super.key, required this.userId});

  @override
  State<StoreOperationsPreferencesScreen> createState() =>
      _StoreOperationsPreferencesScreenState();
}

class _StoreOperationsPreferencesScreenState
    extends State<StoreOperationsPreferencesScreen> {
  bool _isLoading = true;
  bool _substitutionsEnabled = true;
  bool _pickupAlerts = true;
  bool _inventoryWarnings = true;
  int _prepBufferMinutes = 8;
  int _packingLeadMinutes = 4;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final remote = await OperatorPreferencesService.load(
      appVariant: 'store_owner',
      userId: widget.userId,
    );
    if (remote.isNotEmpty) {
      _substitutionsEnabled = remote['substitutions_enabled'] as bool? ?? true;
      _pickupAlerts = remote['pickup_alerts'] as bool? ?? true;
      _inventoryWarnings = remote['inventory_warnings'] as bool? ?? true;
      _prepBufferMinutes = remote['prep_buffer_minutes'] as int? ?? 8;
      _packingLeadMinutes = remote['packing_lead_minutes'] as int? ?? 4;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _persist() async {
    await OperatorPreferencesService.save(
      appVariant: 'store_owner',
      userId: widget.userId,
      settings: {
        'substitutions_enabled': _substitutionsEnabled,
        'pickup_alerts': _pickupAlerts,
        'inventory_warnings': _inventoryWarnings,
        'prep_buffer_minutes': _prepBufferMinutes,
        'packing_lead_minutes': _packingLeadMinutes,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store operations')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _OpsCard(
                  title: 'Fulfillment preferences',
                  subtitle:
                      'These settings control how this store handles substitutions, pickup timing, and stock attention.',
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enable substitutions'),
                        subtitle: const Text(
                          'Allow replacement proposals when an ordered item is unavailable.',
                        ),
                        value: _substitutionsEnabled,
                        onChanged: (value) =>
                            setState(() => _substitutionsEnabled = value),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Pickup alerts'),
                        subtitle: const Text(
                          'Push reminders when orders are ready for rider pickup.',
                        ),
                        value: _pickupAlerts,
                        onChanged: (value) =>
                            setState(() => _pickupAlerts = value),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Inventory warnings'),
                        subtitle: const Text(
                          'Highlight low-stock items during active demand spikes.',
                        ),
                        value: _inventoryWarnings,
                        onChanged: (value) =>
                            setState(() => _inventoryWarnings = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _OpsCard(
                  title: 'Timing controls',
                  subtitle:
                      'Set realistic packing and buffer windows so the operational timeline reflects the store floor.',
                  child: Column(
                    children: [
                      _SliderTile(
                        label: 'Preparation buffer',
                        value: _prepBufferMinutes,
                        min: 2,
                        max: 25,
                        onChanged: (value) =>
                            setState(() => _prepBufferMinutes = value),
                      ),
                      _SliderTile(
                        label: 'Packing lead',
                        value: _packingLeadMinutes,
                        min: 1,
                        max: 15,
                        onChanged: (value) =>
                            setState(() => _packingLeadMinutes = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await _persist();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Store operation settings saved'),
                        ),
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            error.toString().replaceFirst('Bad state: ', ''),
                          ),
                          backgroundColor: AppTheme.primaryRed,
                        ),
                      );
                    }
                  },
                  child: const Text('Save store preferences'),
                ),
              ],
            ),
    );
  }
}

class _OpsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _OpsCard({
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
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textMedium, height: 1.45),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '$value min',
              style: const TextStyle(color: AppTheme.textMedium),
            ),
          ],
        ),
        Slider(
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          value: value.toDouble(),
          onChanged: (next) => onChanged(next.round()),
        ),
      ],
    );
  }
}
