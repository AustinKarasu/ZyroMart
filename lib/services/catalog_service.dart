import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../models/store.dart';
import '../services/supabase_service.dart';

/// CatalogService — LIVE data only. No mock/demo fallbacks.
class CatalogService extends ChangeNotifier {
  List<Category> _categories = [];
  List<Product> _products = [];
  List<Store> _stores = [];
  final Map<String, List<Product>> _searchCache = {};
  bool _isLoading = false;
  String? _loadError;

  List<Category> get categories => List.unmodifiable(_categories);
  List<Product> get products => List.unmodifiable(_products);
  List<Store> get stores => List.unmodifiable(_stores);
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

  List<Product> smartSearch(
    String query, {
    String localeCode = 'en-IN',
    Set<String> dietFilters = const {},
  }) {
    final normalized = query.trim().toLowerCase();
    final cacheKey = '$localeCode|$normalized|${dietFilters.join(",")}';
    if (_searchCache.containsKey(cacheKey)) {
      return List.unmodifiable(_searchCache[cacheKey]!);
    }

    var matches = _products.where((product) {
      final text = [
        product.name,
        product.description,
        product.unit,
        _categoryName(product.categoryId),
        _storeName(product.storeId),
      ].join(' ').toLowerCase();
      final queryMatch = normalized.isEmpty || text.contains(normalized);
      final dietMatch =
          dietFilters.isEmpty || _matchesDietFilter(product, dietFilters);
      return queryMatch && dietMatch;
    }).toList();

    matches.sort((a, b) {
      final exactA = a.name.toLowerCase() == normalized ? 1 : 0;
      final exactB = b.name.toLowerCase() == normalized ? 1 : 0;
      if (exactA != exactB) return exactB.compareTo(exactA);
      final startsA = a.name.toLowerCase().startsWith(normalized) ? 1 : 0;
      final startsB = b.name.toLowerCase().startsWith(normalized) ? 1 : 0;
      if (startsA != startsB) return startsB.compareTo(startsA);
      return b.reviewCount.compareTo(a.reviewCount);
    });

    _searchCache[cacheKey] = matches;
    return List.unmodifiable(matches);
  }

  List<Product> recommendedProducts({
    int limit = 8,
    Set<String> dietFilters = const {},
  }) {
    final results =
        _products
            .where(
              (p) => dietFilters.isEmpty || _matchesDietFilter(p, dietFilters),
            )
            .toList()
          ..sort((a, b) {
            final scoreA = (a.rating * 100) + a.reviewCount;
            final scoreB = (b.rating * 100) + b.reviewCount;
            return scoreB.compareTo(scoreA);
          });
    return results.take(limit).toList();
  }

  Future<void> load() async {
    if (!SupabaseService.isInitialized) {
      _loadError = 'Backend not connected. Configure Supabase credentials.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        SupabaseService.getCategories(),
        SupabaseService.getProducts(),
        SupabaseService.getStores(),
      ]);

      _categories = List<Map<String, dynamic>>.from(
        results[0] as List,
      ).map(_mapCategory).toList();
      _products = List<Map<String, dynamic>>.from(
        results[1] as List,
      ).map(_mapProduct).toList();
      _stores = List<Map<String, dynamic>>.from(
        results[2] as List,
      ).map(_mapStore).toList();
      _searchCache.clear();
    } catch (e) {
      _loadError = 'Failed to load catalog: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Category _mapCategory(Map<String, dynamic> row) {
    return Category(
      id: row['id'].toString(),
      name: _normalizeText((row['name'] ?? 'Category').toString()),
      icon: _iconFromName((row['icon_name'] ?? '').toString()),
      color: _colorFromHex((row['color'] ?? '#B71C1C').toString()),
      imageUrl: _normalizeText((row['image_url'] ?? '').toString()),
    );
  }

  Product _mapProduct(Map<String, dynamic> row) {
    return Product(
      id: row['id'].toString(),
      name: _normalizeText((row['name'] ?? 'Product').toString()),
      description: _normalizeText((row['description'] ?? '').toString()),
      price: ((row['price'] ?? 0) as num).toDouble(),
      originalPrice: row['original_price'] == null
          ? null
          : ((row['original_price']) as num).toDouble(),
      imageUrl: _normalizeText((row['image_url'] ?? '').toString()),
      categoryId: (row['category_id'] ?? '').toString(),
      storeId: (row['store_id'] ?? '').toString(),
      inStock: row['in_stock'] ?? true,
      stockQuantity: (row['stock_quantity'] ?? 0) as int,
      unit: _normalizeText((row['unit'] ?? 'piece').toString()),
      rating: ((row['rating'] ?? 4.0) as num).toDouble(),
      reviewCount: (row['review_count'] ?? 0) as int,
    );
  }

  Store _mapStore(Map<String, dynamic> row) {
    return Store(
      id: row['id'].toString(),
      name: _normalizeText((row['name'] ?? 'Store').toString()),
      address: _normalizeText((row['address'] ?? '').toString()),
      location: LatLng(
        ((row['latitude'] ?? 0) as num).toDouble(),
        ((row['longitude'] ?? 0) as num).toDouble(),
      ),
      rating: ((row['rating'] ?? 4.5) as num).toDouble(),
      imageUrl: _normalizeText((row['image_url'] ?? '').toString()),
      isOpen: row['is_open'] ?? true,
      ownerId: (row['owner_id'] ?? '').toString(),
      phone: _normalizeText((row['phone'] ?? '').toString()),
      openTime: _normalizeText((row['open_time'] ?? '08:00 AM').toString()),
      closeTime: _normalizeText((row['close_time'] ?? '10:00 PM').toString()),
      totalOrders: (row['total_orders'] ?? 0) as int,
      totalRevenue: ((row['total_revenue'] ?? 0) as num).toDouble(),
    );
  }

  String _normalizeText(String value) {
    if (value.isEmpty) return value;
    const suspicious = ['Ã', 'Â', 'â€', 'â‚¬', ''];
    if (!suspicious.any(value.contains)) return value;
    try {
      return utf8.decode(latin1.encode(value), allowMalformed: true);
    } catch (_) {
      return value;
    }
  }

  IconData _iconFromName(String name) {
    const map = <String, IconData>{
      'eco': Icons.eco,
      'breakfast_dining': Icons.breakfast_dining,
      'cookie': Icons.cookie,
      'local_drink': Icons.local_drink,
      'cake': Icons.cake,
      'face': Icons.face,
      'set_meal': Icons.set_meal,
      'child_care': Icons.child_care,
      'ac_unit': Icons.ac_unit,
      'local_pizza': Icons.local_pizza,
      'icecream': Icons.icecream,
      'cleaning_services': Icons.cleaning_services,
    };
    return map[name] ?? Icons.category_outlined;
  }

  Color _colorFromHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    return Color(int.tryParse(value, radix: 16) ?? 0xFFB71C1C);
  }

  String _categoryName(String categoryId) {
    final match = _categories.where((c) => c.id == categoryId);
    return match.isEmpty ? '' : match.first.name;
  }

  String _storeName(String storeId) {
    final match = _stores.where((s) => s.id == storeId);
    return match.isEmpty ? '' : match.first.name;
  }

  bool _matchesDietFilter(Product product, Set<String> dietFilters) {
    final text = '${product.name} ${product.description}'.toLowerCase();
    final nonVegSignals = ['chicken', 'salmon', 'egg', 'meat', 'fish'];
    final veganSignals = [
      'banana',
      'apple',
      'spinach',
      'tomato',
      'onion',
      'potato',
      'nuts',
    ];

    for (final filter in dietFilters.map((f) => f.toLowerCase())) {
      if (filter == 'vegetarian') {
        if (nonVegSignals.any(text.contains)) return false;
      } else if (filter == 'vegan') {
        if (!veganSignals.any(text.contains)) return false;
      } else if (filter == 'high-protein') {
        if (![
          'egg',
          'milk',
          'paneer',
          'chicken',
          'salmon',
          'nuts',
        ].any(text.contains)) {
          return false;
        }
      } else if (filter == 'snacks') {
        if (![
          'chips',
          'cookie',
          'chocolate',
          'namkeen',
          'cake',
        ].any(text.contains)) {
          return false;
        }
      } else if (!text.contains(filter)) {
        return false;
      }
    }
    return true;
  }
}
