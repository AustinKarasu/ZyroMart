import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';

class LocalStateService {
  static Future<void> saveCart(
    String scope,
    List<CartItem> items, {
    String? appliedCoupon,
    double deliveryTip = 0,
    double couponDiscount = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'items': items.map(_cartItemToMap).toList(),
      'applied_coupon': appliedCoupon,
      'delivery_tip': deliveryTip,
      'coupon_discount': couponDiscount,
    };
    await prefs.setString(_cartKey(scope), jsonEncode(payload));
  }

  static Future<Map<String, dynamic>?> loadCart(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cartKey(scope));
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return decoded;
  }

  static Future<void> clearCart(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey(scope));
  }

  static Future<void> saveOrders(
    String scope,
    List<Order> orders, {
    required Map<String, List<Map<String, dynamic>>> statusEvents,
    required Map<String, List<Map<String, dynamic>>> reservations,
    required Map<String, List<Map<String, dynamic>>> routeUpdates,
    required Map<String, Map<String, dynamic>> proofByOrderId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'orders': orders.map(_orderToMap).toList(),
      'status_events': statusEvents,
      'reservations': reservations,
      'route_updates': routeUpdates,
      'proof': proofByOrderId,
    };
    await prefs.setString(_ordersKey(scope), jsonEncode(payload));
  }

  static Future<Map<String, dynamic>?> loadOrders(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ordersKey(scope));
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return decoded;
  }

  static Map<String, dynamic> cartItemToMap(CartItem item) => _cartItemToMap(item);

  static CartItem cartItemFromMap(Map<String, dynamic> map) {
    return CartItem(
      product: _productFromMap(Map<String, dynamic>.from(map['product'] as Map)),
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  static Order orderFromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'].toString(),
      items: (map['items'] as List? ?? const [])
          .map((entry) => cartItemFromMap(Map<String, dynamic>.from(entry as Map)))
          .toList(),
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (map['delivery_fee'] as num?)?.toDouble() ?? 0,
      platformFee: (map['platform_fee'] as num?)?.toDouble() ?? 0,
      handlingFee: (map['handling_fee'] as num?)?.toDouble() ?? 0,
      deliveryTip: (map['delivery_tip'] as num?)?.toDouble() ?? 0,
      couponDiscount: (map['coupon_discount'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => OrderStatus.placed,
      ),
      customerId: (map['customer_id'] ?? '').toString(),
      customerName: (map['customer_name'] ?? '').toString(),
      customerPhone: (map['customer_phone'] ?? '').toString(),
      storeId: (map['store_id'] ?? '').toString(),
      storeName: (map['store_name'] ?? '').toString(),
      deliveryPersonId: map['delivery_person_id']?.toString(),
      deliveryPersonName: map['delivery_person_name']?.toString(),
      deliveryAddress: (map['delivery_address'] ?? '').toString(),
      placedAt: DateTime.tryParse((map['placed_at'] ?? '').toString()) ??
          DateTime.now(),
      estimatedDelivery: DateTime.tryParse(
            (map['estimated_delivery'] ?? '').toString(),
          ) ??
          DateTime.now(),
      customerLocation: _latLngFromMap(
        Map<String, dynamic>.from(map['customer_location'] as Map),
      ),
      storeLocation: _latLngFromMap(
        Map<String, dynamic>.from(map['store_location'] as Map),
      ),
      deliveryPersonLocation: map['delivery_person_location'] == null
          ? null
          : _latLngFromMap(
              Map<String, dynamic>.from(map['delivery_person_location'] as Map),
            ),
      notes: map['notes']?.toString(),
      paymentMethod: (map['payment_method'] ?? 'cod').toString(),
      deliveryVerificationCode:
          (map['delivery_verification_code'] ?? '').toString(),
    );
  }

  static String _cartKey(String scope) => 'local_state::$scope::cart';
  static String _ordersKey(String scope) => 'local_state::$scope::orders';

  static Map<String, dynamic> _cartItemToMap(CartItem item) => {
        'product': _productToMap(item.product),
        'quantity': item.quantity,
      };

  static Map<String, dynamic> _orderToMap(Order order) => {
        'id': order.id,
        'items': order.items.map(_cartItemToMap).toList(),
        'total_amount': order.totalAmount,
        'delivery_fee': order.deliveryFee,
        'platform_fee': order.platformFee,
        'handling_fee': order.handlingFee,
        'delivery_tip': order.deliveryTip,
        'coupon_discount': order.couponDiscount,
        'status': order.status.name,
        'customer_id': order.customerId,
        'customer_name': order.customerName,
        'customer_phone': order.customerPhone,
        'store_id': order.storeId,
        'store_name': order.storeName,
        'delivery_person_id': order.deliveryPersonId,
        'delivery_person_name': order.deliveryPersonName,
        'delivery_address': order.deliveryAddress,
        'placed_at': order.placedAt.toIso8601String(),
        'estimated_delivery': order.estimatedDelivery.toIso8601String(),
        'customer_location': _latLngToMap(order.customerLocation),
        'store_location': _latLngToMap(order.storeLocation),
        'delivery_person_location': order.deliveryPersonLocation == null
            ? null
            : _latLngToMap(order.deliveryPersonLocation!),
        'notes': order.notes,
        'payment_method': order.paymentMethod,
        'delivery_verification_code': order.deliveryVerificationCode,
      };

  static Map<String, dynamic> _productToMap(Product product) => {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'original_price': product.originalPrice,
        'image_url': product.imageUrl,
        'category_id': product.categoryId,
        'store_id': product.storeId,
        'in_stock': product.inStock,
        'stock_quantity': product.stockQuantity,
        'unit': product.unit,
        'rating': product.rating,
        'review_count': product.reviewCount,
      };

  static Product _productFromMap(Map<String, dynamic> map) => Product(
        id: map['id'].toString(),
        name: (map['name'] ?? '').toString(),
        description: (map['description'] ?? '').toString(),
        price: (map['price'] as num?)?.toDouble() ?? 0,
        originalPrice: (map['original_price'] as num?)?.toDouble(),
        imageUrl: (map['image_url'] ?? '').toString(),
        categoryId: (map['category_id'] ?? '').toString(),
        storeId: (map['store_id'] ?? '').toString(),
        inStock: map['in_stock'] as bool? ?? true,
        stockQuantity: (map['stock_quantity'] as num?)?.toInt() ?? 0,
        unit: (map['unit'] ?? 'piece').toString(),
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      );

  static Map<String, dynamic> _latLngToMap(LatLng value) => {
        'lat': value.latitude,
        'lng': value.longitude,
      };

  static LatLng _latLngFromMap(Map<String, dynamic> map) => LatLng(
        (map['lat'] as num?)?.toDouble() ?? 0,
        (map['lng'] as num?)?.toDouble() ?? 0,
      );
}
