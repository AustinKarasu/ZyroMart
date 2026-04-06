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

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    if (!SupabaseService.isInitialized) return;
    setState(() => _loading = true);
    final rows = await SupabaseService.getRestockSubscriptions()
        .catchError((_) => <Map<String, dynamic>>[]);
    for (final row in rows) {
      final productId = (row['product_id'] ?? '').toString();
      if (productId.isEmpty) continue;
      _activeProducts.add(productId);
      _cadenceByProduct[productId] = (row['cadence'] ?? 'weekly').toString();
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products =
        context.watch<CatalogService>().recommendedProducts(limit: 12);
    return Scaffold(
      appBar: AppBar(title: const Text('Auto-restock')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Put essentials on autopilot. Choose a cadence and the app will keep reminding you before you run out.',
                  style: TextStyle(
                    color: AppTheme.textMedium,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                ...products.map((product) => _productTile(product)),
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
                      'Rs ${product.price.toInt()} • ${product.unit}',
                      style: const TextStyle(color: AppTheme.textMedium),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: active,
                onChanged: (value) => _saveSubscription(
                  product: product,
                  enabled: value,
                ),
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
              decoration: const InputDecoration(
                labelText: 'Restock cadence',
              ),
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
    final chosenCadence = cadence ?? _cadenceByProduct[product.id] ?? 'weekly';
    setState(() {
      if (enabled) {
        _activeProducts.add(product.id);
        _cadenceByProduct[product.id] = chosenCadence;
      } else {
        _activeProducts.remove(product.id);
      }
    });
    if (!SupabaseService.isInitialized) return;
    await SupabaseService.upsertRestockSubscription({
      'product_id': product.id,
      'cadence': chosenCadence,
      'quantity': 1,
      'is_active': enabled,
      'next_run_at': _nextRunFor(chosenCadence).toIso8601String(),
    }).catchError((_) {});
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
