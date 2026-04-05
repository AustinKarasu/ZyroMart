import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../services/mock_data.dart';

class OrderService extends ChangeNotifier {
  final List<Order> _orders = [];
  Timer? _simulationTimer;
  final Random _random = Random();

  OrderService() {
    _orders.addAll(MockData.sampleOrders);
    _startDeliverySimulation();
  }

  List<Order> get orders => List.unmodifiable(_orders);

  List<Order> get activeOrders => _orders
      .where((o) =>
          o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled)
      .toList();

  List<Order> get pastOrders => _orders
      .where((o) =>
          o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled)
      .toList();

  List<Order> get pendingDeliveryOrders => _orders
      .where((o) =>
          o.status == OrderStatus.readyForPickup ||
          o.status == OrderStatus.outForDelivery)
      .toList();

  List<Order> get storeOrders => _orders
      .where((o) => o.status != OrderStatus.cancelled)
      .toList();

  Order? getOrder(String id) {
    final matches = _orders.where((o) => o.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  Order placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    required String deliveryAddress,
    required LatLng customerLocation,
    String? notes,
  }) {
    final store = MockData.stores[0];
    final order = Order(
      id: 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      items: items.map((i) => CartItem(product: i.product, quantity: i.quantity)).toList(),
      totalAmount: totalAmount,
      status: OrderStatus.placed,
      customerId: MockData.defaultCustomer.id,
      customerName: MockData.defaultCustomer.name,
      storeId: store.id,
      storeName: store.name,
      deliveryAddress: deliveryAddress,
      placedAt: DateTime.now(),
      estimatedDelivery: DateTime.now().add(const Duration(hours: 24)),
      customerLocation: customerLocation,
      storeLocation: store.location,
      notes: notes,
    );
    _orders.insert(0, order);
    notifyListeners();

    _simulateOrderProgress(order);
    return order;
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    final order = getOrder(orderId);
    if (order != null) {
      order.status = status;
      if (status == OrderStatus.outForDelivery) {
        final dp = MockData.deliveryPersons[_random.nextInt(MockData.deliveryPersons.length)];
        order.deliveryPersonId = dp.id;
        order.deliveryPersonName = dp.name;
        order.deliveryPersonLocation = dp.location;
      }
      notifyListeners();
    }
  }

  void _simulateOrderProgress(Order order) {
    int step = 0;
    Timer.periodic(const Duration(seconds: 8), (timer) {
      step++;
      switch (step) {
        case 1:
          order.status = OrderStatus.confirmed;
          break;
        case 2:
          order.status = OrderStatus.preparing;
          break;
        case 3:
          order.status = OrderStatus.readyForPickup;
          break;
        case 4:
          final dp = MockData.deliveryPersons[_random.nextInt(MockData.deliveryPersons.length)];
          order.status = OrderStatus.outForDelivery;
          order.deliveryPersonId = dp.id;
          order.deliveryPersonName = dp.name;
          order.deliveryPersonLocation = dp.location;
          break;
        default:
          timer.cancel();
          return;
      }
      notifyListeners();
    });
  }

  void _startDeliverySimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      bool changed = false;
      for (final order in _orders) {
        if (order.status == OrderStatus.outForDelivery &&
            order.deliveryPersonLocation != null) {
          final currentLoc = order.deliveryPersonLocation!;
          final targetLoc = order.customerLocation;
          final newLat = currentLoc.latitude +
              (targetLoc.latitude - currentLoc.latitude) * 0.05 +
              (_random.nextDouble() - 0.5) * 0.0005;
          final newLng = currentLoc.longitude +
              (targetLoc.longitude - currentLoc.longitude) * 0.05 +
              (_random.nextDouble() - 0.5) * 0.0005;
          order.deliveryPersonLocation = LatLng(newLat, newLng);
          changed = true;
        }
      }
      if (changed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}
