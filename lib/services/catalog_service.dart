import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../models/store.dart';
import '../services/mock_data.dart';
import '../services/supabase_service.dart';

class CatalogService extends ChangeNotifier {
  List<Category> _categories = List.of(MockData.categories);
  List<Product> _products = List.of(MockData.products);
  List<Store> _stores = List.of(MockData.stores);
  final Map<String, List<Product>> _searchCache = {};
  bool _isLoading = false;

  List<Category> get categories => List.unmodifiable(_categories);
  List<Product> get products => List.unmodifiable(_products);
  List<Store> get stores => List.unmodifiable(_stores);
  bool get isLoading => _isLoading;

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
      if (exactA != exactB) {
        return exactB.compareTo(exactA);
      }
      final startsA = a.name.toLowerCase().startsWith(normalized) ? 1 : 0;
      final startsB = b.name.toLowerCase().startsWith(normalized) ? 1 : 0;
      if (startsA != startsB) {
        return startsB.compareTo(startsA);
      }
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
              (product) =>
                  dietFilters.isEmpty ||
                  _matchesDietFilter(product, dietFilters),
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
    if (!SupabaseService.isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      final categoryRows = await SupabaseService.getCategories();
      final productRows = await SupabaseService.getProducts();
      final storeRows = await SupabaseService.getStores();

      if (categoryRows.isNotEmpty) {
        _categories = _mergeCategories(categoryRows.map(_mapCategory).toList());
      }
      if (productRows.isNotEmpty) {
        _products = productRows.map(_mapProduct).toList();
      }
      if (storeRows.isNotEmpty) {
        _stores = storeRows.map(_mapStore).toList();
      }
    } catch (_) {
      // Keep the seeded fallback already in memory.
    } finally {
      _searchCache.clear();
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Category> _mergeCategories(List<Category> liveCategories) {
    final merged = [...liveCategories];
    final existingNames = liveCategories
        .map((category) => category.name.toLowerCase())
        .toSet();
    for (final fallback in MockData.categories) {
      if (!existingNames.contains(fallback.name.toLowerCase())) {
        merged.add(fallback);
      }
    }
    return merged;
  }

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
    const suspicious = ['Ã', 'Â', 'â€', 'â‚¬', '�'];
    if (!suspicious.any(value.contains)) {
      return value;
    }
    try {
      return utf8.decode(latin1.encode(value), allowMalformed: true);
    } catch (_) {
      return value;
    }
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'eco':
        return Icons.eco;
      case 'breakfast_dining':
        return Icons.breakfast_dining;
      case 'cookie':
        return Icons.cookie;
      case 'local_drink':
        return Icons.local_drink;
      case 'cake':
        return Icons.cake;
      case 'face':
        return Icons.face;
      default:
        return Icons.category_outlined;
    }
  }

  Color _colorFromHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    return Color(int.tryParse(value, radix: 16) ?? 0xFFB71C1C);
  }

  String _categoryName(String categoryId) {
    final match = _categories.where((category) => category.id == categoryId);
    return match.isEmpty ? '' : match.first.name;
  }

  String _storeName(String storeId) {
    final match = _stores.where((store) => store.id == storeId);
    return match.isEmpty ? '' : match.first.name;
  }

  bool _matchesDietFilter(Product product, Set<String> dietFilters) {
    final description = product.description.toLowerCase();
    final name = product.name.toLowerCase();
    final text = '$name $description';
    final vegetarianSignals = [
      'milk',
      'paneer',
      'bread',
      'tea',
      'juice',
      'chips',
      'cake',
    ];
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

    for (final filter in dietFilters.map((item) => item.toLowerCase())) {
      if (filter == 'vegetarian') {
        if (nonVegSignals.any(text.contains)) return false;
        continue;
      }
      if (filter == 'vegan') {
        if (!veganSignals.any(text.contains)) return false;
        continue;
      }
      if (filter == 'high-protein') {
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
        continue;
      }
      if (filter == 'snacks') {
        if (![
          'chips',
          'cookie',
          'chocolate',
          'namkeen',
          'cake',
        ].any(text.contains)) {
          return false;
        }
        continue;
      }
      if (!text.contains(filter)) {
        return false;
      }
    }

    if (dietFilters.map((item) => item.toLowerCase()).contains('vegetarian')) {
      return vegetarianSignals.any(text.contains) ||
          !nonVegSignals.any(text.contains);
    }
    return true;
  }
}
