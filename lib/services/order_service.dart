import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/user.dart';
import 'mock_data.dart';

class OrderService extends ChangeNotifier {
  final List<Order> _orders = [];
  final Map<String, Timer> _progressTimers = {};
  Timer? _simulationTimer;
  final Random _random = Random();
  AppUser? _viewer;

  OrderService() {
    _orders.addAll(MockData.sampleOrders);
    _startDeliverySimulation();
    for (final order in _orders) {
      _ensureProgressForOrder(order);
    }
  }

  void bindUser(AppUser? user) {
    if (_viewer?.id == user?.id && _viewer?.role == user?.role) {
      return;
    }
    _viewer = user;
    notifyListeners();
  }

  List<Order> get orders => List.unmodifiable(_visibleOrders);

  List<Order> get activeOrders => _visibleOrders
      .where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled)
      .toList();

  List<Order> get pastOrders => _visibleOrders
      .where((o) => o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled)
      .toList();

  List<Order> get pendingDeliveryOrders => _visibleOrders
      .where((o) => o.status == OrderStatus.readyForPickup || o.status == OrderStatus.outForDelivery)
      .toList();

  List<Order> get storeOrders => _visibleOrders.where((o) => o.status != OrderStatus.cancelled).toList();

  Order? getOrder(String id) {
    final matches = _orders.where((o) => o.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  Order placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    required double deliveryFee,
    required String deliveryAddress,
    required LatLng customerLocation,
    String? notes,
  }) {
    final customer = _viewer ?? MockData.defaultCustomer;
    final store = MockData.stores.first;
    final order = Order(
      id: 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      items: items.map((i) => CartItem(product: i.product, quantity: i.quantity)).toList(),
      totalAmount: totalAmount,
      deliveryFee: deliveryFee,
      status: OrderStatus.placed,
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      storeId: store.id,
      storeName: store.name,
      deliveryAddress: deliveryAddress,
      placedAt: DateTime.now(),
      estimatedDelivery: DateTime.now().add(const Duration(minutes: 32)),
      customerLocation: customerLocation,
      storeLocation: store.location,
      notes: notes,
    );
    _orders.insert(0, order);
    _ensureProgressForOrder(order);
    notifyListeners();
    return order;
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    final order = getOrder(orderId);
    if (order == null || order.status == status) {
      return;
    }

    order.status = status;
    if (status == OrderStatus.outForDelivery) {
      final deliveryPartner = _viewer?.role == UserRole.delivery
          ? _viewer!
          : MockData.deliveryPersons[_random.nextInt(MockData.deliveryPersons.length)];
      order.deliveryPersonId = deliveryPartner.id;
      order.deliveryPersonName = deliveryPartner.name;
      order.deliveryPersonLocation = deliveryPartner.location;
    }

    if (status == OrderStatus.delivered || status == OrderStatus.cancelled) {
      _progressTimers.remove(order.id)?.cancel();
    }

    notifyListeners();
  }

  List<Order> get _visibleOrders {
    if (_viewer == null) {
      return _orders;
    }

    switch (_viewer!.role) {
      case UserRole.customer:
        return _orders.where((order) => order.customerId == _viewer!.id).toList();
      case UserRole.storeOwner:
        return _orders.where((order) => order.storeId == MockData.stores.first.id).toList();
      case UserRole.delivery:
        return _orders.where((order) {
          return order.status == OrderStatus.readyForPickup || order.deliveryPersonId == _viewer!.id;
        }).toList();
    }
  }

  void _ensureProgressForOrder(Order order) {
    if (_progressTimers.containsKey(order.id) ||
        order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled ||
        order.status == OrderStatus.outForDelivery) {
      return;
    }

    _progressTimers[order.id] = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (order.status == OrderStatus.cancelled || order.status == OrderStatus.delivered) {
        timer.cancel();
        _progressTimers.remove(order.id);
        return;
      }

      switch (order.status) {
        case OrderStatus.placed:
          order.status = OrderStatus.confirmed;
          break;
        case OrderStatus.confirmed:
          order.status = OrderStatus.preparing;
          break;
        case OrderStatus.preparing:
          order.status = OrderStatus.readyForPickup;
          break;
        case OrderStatus.readyForPickup:
          final dp = MockData.deliveryPersons[_random.nextInt(MockData.deliveryPersons.length)];
          order.status = OrderStatus.outForDelivery;
          order.deliveryPersonId = dp.id;
          order.deliveryPersonName = dp.name;
          order.deliveryPersonLocation = dp.location;
          timer.cancel();
          _progressTimers.remove(order.id);
          break;
        case OrderStatus.outForDelivery:
        case OrderStatus.delivered:
        case OrderStatus.cancelled:
          timer.cancel();
          _progressTimers.remove(order.id);
          return;
      }
      notifyListeners();
    });
  }

  void _startDeliverySimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      var changed = false;
      for (final order in _orders) {
        if (order.status == OrderStatus.outForDelivery && order.deliveryPersonLocation != null) {
          final currentLoc = order.deliveryPersonLocation!;
          final targetLoc = order.customerLocation;
          final newLat = currentLoc.latitude +
              (targetLoc.latitude - currentLoc.latitude) * 0.16 +
              (_random.nextDouble() - 0.5) * 0.00035;
          final newLng = currentLoc.longitude +
              (targetLoc.longitude - currentLoc.longitude) * 0.16 +
              (_random.nextDouble() - 0.5) * 0.00035;
          order.deliveryPersonLocation = LatLng(newLat, newLng);
          if ((targetLoc.latitude - newLat).abs() < 0.0008 &&
              (targetLoc.longitude - newLng).abs() < 0.0008) {
            order.status = OrderStatus.delivered;
            _progressTimers.remove(order.id)?.cancel();
          }
          changed = true;
        }
      }
      if (changed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    for (final timer in _progressTimers.values) {
      timer.cancel();
    }
    _progressTimers.clear();
    super.dispose();
  }
}
