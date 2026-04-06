import 'package:flutter/material.dart';

import '../../services/operator_preferences_service.dart';
import '../../theme/app_theme.dart';

class DeliveryOperationsPreferencesScreen extends StatefulWidget {
  final String userId;

  const DeliveryOperationsPreferencesScreen({
    super.key,
    required this.userId,
  });

  @override
  State<DeliveryOperationsPreferencesScreen> createState() => _DeliveryOperationsPreferencesScreenState();
}

class _DeliveryOperationsPreferencesScreenState extends State<DeliveryOperationsPreferencesScreen> {
  bool _isLoading = true;
  bool _shareLiveLocation = true;
  bool _proofChecklist = true;
  bool _emergencyShortcut = true;
  String _preferredMapMode = 'balanced';
  String _handoffTemplate = 'Delivered to customer after OTP verification.';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final remote = await OperatorPreferencesService.load(
      appVariant: 'delivery',
      userId: widget.userId,
    );
    if (remote.isNotEmpty) {
      _shareLiveLocation = remote['share_live_location'] as bool? ?? true;
      _proofChecklist = remote['proof_checklist'] as bool? ?? true;
      _emergencyShortcut = remote['emergency_shortcut'] as bool? ?? true;
      _preferredMapMode = (remote['preferred_map_mode'] ?? _preferredMapMode).toString();
      _handoffTemplate = (remote['handoff_template'] ?? _handoffTemplate).toString();
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _persist() async {
    await OperatorPreferencesService.save(
      appVariant: 'delivery',
      userId: widget.userId,
      settings: {
        'share_live_location': _shareLiveLocation,
        'proof_checklist': _proofChecklist,
        'emergency_shortcut': _emergencyShortcut,
        'preferred_map_mode': _preferredMapMode,
        'handoff_template': _handoffTemplate,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery preferences')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DeliveryCard(
                  title: 'On-road controls',
                  subtitle: 'Tune location sharing, proof-of-delivery guidance, and emergency shortcuts for the rider app.',
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Share live location'),
                        subtitle: const Text('Continuously update order tracking when a delivery is active.'),
                        value: _shareLiveLocation,
                        onChanged: (value) => setState(() => _shareLiveLocation = value),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Proof checklist'),
                        subtitle: const Text('Show reminder guidance before confirming delivered handoff.'),
                        value: _proofChecklist,
                        onChanged: (value) => setState(() => _proofChecklist = value),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Emergency shortcut'),
                        subtitle: const Text('Keep the emergency help action highlighted on active routes.'),
                        value: _emergencyShortcut,
                        onChanged: (value) => setState(() => _emergencyShortcut = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _DeliveryCard(
                  title: 'Route and handoff',
                  subtitle: 'Choose a routing style and define the default handoff note riders should see while completing orders.',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _preferredMapMode,
                        decoration: const InputDecoration(labelText: 'Preferred route mode'),
                        items: const [
                          DropdownMenuItem(value: 'balanced', child: Text('Balanced')),
                          DropdownMenuItem(value: 'fastest', child: Text('Fastest')),
                          DropdownMenuItem(value: 'safer', child: Text('Safer streets')),
                        ],
                        onChanged: (value) => setState(() => _preferredMapMode = value ?? 'balanced'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _handoffTemplate,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Default handoff note'),
                        onChanged: (value) => _handoffTemplate = value,
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
                      const SnackBar(content: Text('Delivery preferences saved')),
                    );
                  },
                  child: const Text('Save rider preferences'),
                ),
              ],
            ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _DeliveryCard({
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
