import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/catalog_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class RestockSubscriptionsScreen extends StatefulWidget {
  const RestockSubscriptionsScreen({super.key});

  @override
  State<RestockSubscriptionsScreen> createState() =>
      _RestockSubscriptionsScreenState();
}

class _RestockSubscriptionsScreenState
    extends State<RestockSubscriptionsScreen> {
  final Map<String, String> _cadenceByProduct = {};
  final Set<String> _activeProducts = {};
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _activeProducts.clear();
      _cadenceByProduct.clear();
    });

    if (!SupabaseService.isInitialized) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = SupabaseService.backendStatusMessage;
        });
      }
      return;
    }

    try {
      final rows = await SupabaseService.getRestockSubscriptions();
      for (final row in rows) {
        final productId = (row['product_id'] ?? '').toString();
        if (productId.isEmpty) continue;
        _activeProducts.add(productId);
        _cadenceByProduct[productId] = (row['cadence'] ?? 'weekly').toString();
      }
    } catch (error) {
      _errorMessage =
          'Could not load live restock subscriptions. ${error.toString()}';
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<CatalogService>().recommendedProducts(
      limit: 12,
    );
    final showEmptyError = _errorMessage != null && _activeProducts.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Auto-restock')),
      body: _loading && _activeProducts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Put essentials on autopilot. Choose a cadence and the app will keep reminding you before you run out.',
                  style: TextStyle(color: AppTheme.textMedium, height: 1.45),
                ),
                const SizedBox(height: 16),
                if (showEmptyError) ...[
                  _RestockStateCard(
                    icon: Icons.cloud_off_rounded,
                    title: 'Live restock subscriptions are unavailable',
                    subtitle: _errorMessage!,
                    actionLabel: 'Retry',
                    onAction: _loadSubscriptions,
                    tone: const Color(0xFFFDEBE8),
                  ),
                ] else ...[
                  if (_errorMessage != null) ...[
                    _RestockStateCard(
                      icon: Icons.warning_amber_rounded,
                      title: 'Backend sync needs attention',
                      subtitle: _errorMessage!,
                      actionLabel: 'Retry',
                      onAction: _loadSubscriptions,
                      tone: const Color(0xFFFFF3E1),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ...products.map((product) => _productTile(product)),
                ],
              ],
            ),
    );
  }

  Widget _productTile(Product product) {
    final active = _activeProducts.contains(product.id);
    final cadence = _cadenceByProduct[product.id] ?? 'weekly';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs ${product.price.toInt()} - ${product.unit}',
                      style: const TextStyle(color: AppTheme.textMedium),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: active,
                onChanged: (value) =>
                    _saveSubscription(product: product, enabled: value),
              ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: cadence,
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _cadenceByProduct[product.id] = value);
                _saveSubscription(
                  product: product,
                  enabled: true,
                  cadence: value,
                );
              },
              decoration: const InputDecoration(labelText: 'Restock cadence'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveSubscription({
    required Product product,
    required bool enabled,
    String? cadence,
  }) async {
    final previousActive = _activeProducts.contains(product.id);
    final previousCadence = _cadenceByProduct[product.id];
    final chosenCadence = cadence ?? previousCadence ?? 'weekly';

    setState(() {
      _errorMessage = null;
      if (enabled) {
        _activeProducts.add(product.id);
        _cadenceByProduct[product.id] = chosenCadence;
      } else {
        _activeProducts.remove(product.id);
      }
    });

    if (!SupabaseService.isInitialized) {
      _restoreSubscriptionState(
        productId: product.id,
        wasActive: previousActive,
        previousCadence: previousCadence,
      );
      _showMessage(SupabaseService.backendStatusMessage, isError: true);
      return;
    }

    try {
      await SupabaseService.upsertRestockSubscription({
        'product_id': product.id,
        'cadence': chosenCadence,
        'quantity': 1,
        'is_active': enabled,
        'next_run_at': _nextRunFor(chosenCadence).toIso8601String(),
      });
      _showMessage(
        enabled
            ? 'Auto-restock saved for ${product.name}.'
            : 'Auto-restock removed for ${product.name}.',
      );
    } catch (error) {
      _restoreSubscriptionState(
        productId: product.id,
        wasActive: previousActive,
        previousCadence: previousCadence,
      );
      final message =
          'Could not save live restock subscription. ${error.toString()}';
      if (mounted) {
        setState(() => _errorMessage = message);
      }
      _showMessage(message, isError: true);
    }
  }

  void _restoreSubscriptionState({
    required String productId,
    required bool wasActive,
    required String? previousCadence,
  }) {
    if (!mounted) return;
    setState(() {
      if (wasActive) {
        _activeProducts.add(productId);
      } else {
        _activeProducts.remove(productId);
      }
      if (previousCadence == null) {
        _cadenceByProduct.remove(productId);
      } else {
        _cadenceByProduct[productId] = previousCadence;
      }
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.primaryRed : AppTheme.success,
      ),
    );
  }

  DateTime _nextRunFor(String cadence) {
    final now = DateTime.now();
    switch (cadence) {
      case 'daily':
        return now.add(const Duration(days: 1));
      case 'monthly':
        return now.add(const Duration(days: 30));
      default:
        return now.add(const Duration(days: 7));
    }
  }
}

class _RestockStateCard extends StatelessWidget {
  const _RestockStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.tone = Colors.white,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final Future<void> Function()? onAction;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppTheme.textMedium),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMedium, height: 1.45),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => onAction!.call(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
