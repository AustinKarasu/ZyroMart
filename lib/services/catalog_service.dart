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
  bool _isLoading = false;

  List<Category> get categories => List.unmodifiable(_categories);
  List<Product> get products => List.unmodifiable(_products);
  List<Store> get stores => List.unmodifiable(_stores);
  bool get isLoading => _isLoading;

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
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Category> _mergeCategories(List<Category> liveCategories) {
    final merged = [...liveCategories];
    final existingNames = liveCategories.map((category) => category.name.toLowerCase()).toSet();
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
      name: (row['name'] ?? 'Category').toString(),
      icon: _iconFromName((row['icon_name'] ?? '').toString()),
      color: _colorFromHex((row['color'] ?? '#B71C1C').toString()),
      imageUrl: (row['image_url'] ?? '').toString(),
    );
  }

  Product _mapProduct(Map<String, dynamic> row) {
    return Product(
      id: row['id'].toString(),
      name: (row['name'] ?? 'Product').toString(),
      description: (row['description'] ?? '').toString(),
      price: ((row['price'] ?? 0) as num).toDouble(),
      originalPrice: row['original_price'] == null
          ? null
          : ((row['original_price']) as num).toDouble(),
      imageUrl: (row['image_url'] ?? '').toString(),
      categoryId: (row['category_id'] ?? '').toString(),
      storeId: (row['store_id'] ?? '').toString(),
      inStock: row['in_stock'] ?? true,
      stockQuantity: (row['stock_quantity'] ?? 0) as int,
      unit: (row['unit'] ?? 'piece').toString(),
      rating: ((row['rating'] ?? 4.0) as num).toDouble(),
      reviewCount: (row['review_count'] ?? 0) as int,
    );
  }

  Store _mapStore(Map<String, dynamic> row) {
    return Store(
      id: row['id'].toString(),
      name: (row['name'] ?? 'Store').toString(),
      address: (row['address'] ?? '').toString(),
      location: LatLng(
        ((row['latitude'] ?? 0) as num).toDouble(),
        ((row['longitude'] ?? 0) as num).toDouble(),
      ),
      rating: ((row['rating'] ?? 4.5) as num).toDouble(),
      imageUrl: (row['image_url'] ?? '').toString(),
      isOpen: row['is_open'] ?? true,
      ownerId: (row['owner_id'] ?? '').toString(),
      phone: (row['phone'] ?? '').toString(),
      openTime: (row['open_time'] ?? '08:00 AM').toString(),
      closeTime: (row['close_time'] ?? '10:00 PM').toString(),
      totalOrders: (row['total_orders'] ?? 0) as int,
      totalRevenue: ((row['total_revenue'] ?? 0) as num).toDouble(),
    );
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
}
