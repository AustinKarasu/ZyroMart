import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/catalog_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _scope() {
    final userId = context.read<AuthService>().currentUser?.id;
    return (userId == null || userId.isEmpty) ? 'guest' : userId;
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _loading = true);
    await _loadLocalSnapshot();
    if (SupabaseService.isInitialized) {
      final rows = await SupabaseService.getRestockSubscriptions().catchError(
        (_) => <Map<String, dynamic>>[],
      );
      if (rows.isNotEmpty) {
        _activeProducts.clear();
        _cadenceByProduct.clear();
        for (final row in rows) {
          final productId = (row['product_id'] ?? '').toString();
          if (productId.isEmpty) continue;
          final enabled = row['is_active'] as bool? ?? true;
          if (enabled) {
            _activeProducts.add(productId);
          }
          _cadenceByProduct[productId] = (row['cadence'] ?? 'weekly')
              .toString();
        }
        await _saveLocalSnapshot();
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadLocalSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(_scope()));
    if (raw == null || raw.isEmpty) {
      return;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    final activeList = decoded['active_products'] as List? ?? const [];
    final cadenceMap = decoded['cadence'] as Map? ?? const {};
    _activeProducts
      ..clear()
      ..addAll(activeList.map((value) => value.toString()));
    _cadenceByProduct
      ..clear()
      ..addAll(
        cadenceMap.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
      );
  }

  Future<void> _saveLocalSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey(_scope()),
      jsonEncode({
        'active_products': _activeProducts.toList(),
        'cadence': _cadenceByProduct,
        'saved_at': DateTime.now().toIso8601String(),
      }),
    );
  }

  String _storageKey(String scope) => 'restock::$scope::subscriptions';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catalog = context.watch<CatalogService>();
    final products = catalog.recommendedProducts(limit: 50).where((product) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return product.name.toLowerCase().contains(q) ||
          product.description.toLowerCase().contains(q) ||
          product.unit.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1418) : const Color(0xFFF6F7F2),
      appBar: AppBar(title: const Text('Auto-restock')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161D22) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: const InputDecoration(
                          hintText: 'Search item for auto-restock',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Set essentials to daily, weekly, or monthly cadence. Restock subscriptions stay account-scoped and sync to backend when online.',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppTheme.textMedium,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (products.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161D22) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'No products match your search.',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppTheme.textMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  ...products.map((product) => _productTile(product, isDark)),
              ],
            ),
    );
  }

  Widget _productTile(Product product, bool isDark) {
    final active = _activeProducts.contains(product.id);
    final cadence = _cadenceByProduct[product.id] ?? 'weekly';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161D22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: AppImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs ${product.price.toInt()} | ${product.unit}',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppTheme.textMedium,
                      ),
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
    await _saveLocalSnapshot();
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
