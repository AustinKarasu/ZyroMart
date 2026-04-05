import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/app_notification.dart';
import '../models/cart_item.dart';
import '../models/delivery_feedback.dart';
import '../models/earnings_summary.dart';
import '../models/order.dart';
import '../models/store.dart';
import '../models/user.dart';
import 'mock_data.dart';

class OrderService extends ChangeNotifier {
  static const double _platformCommissionRate = 0.05;
  static const double _defaultServiceRadiusKm = 5;

  final Distance _distance = const Distance();
  final Random _random = Random();
  final List<Order> _orders = [];
  final Map<String, Timer> _progressTimers = {};
  final Map<String, DeliveryFeedback> _feedbackByOrderId = {};
  final List<AppNotification> _notifications = [];
  final Map<String, double> _heldStoreEarnings = {};
  final Map<String, double> _releasedStoreEarnings = {};
  final Map<String, double> _heldDeliveryEarnings = {};
  final Map<String, double> _releasedDeliveryEarnings = {};
  final Map<String, double> _heldPlatformEarnings = {};
  final Map<String, double> _releasedPlatformEarnings = {};
  final Map<String, double> _serviceRadiusByStoreId = {};
  final Map<String, bool> _settlementReleasedByOrderId = {};
  final Map<String, bool> _deliveryPartnerPromptedByOrderId = {};
  final Map<String, bool> _customerPromptedByOrderId = {};
  Timer? _simulationTimer;
  AppUser? _viewer;

  OrderService() {
    _orders.addAll(MockData.sampleOrders);
    for (final store in MockData.stores) {
      _serviceRadiusByStoreId[store.id] = _defaultServiceRadiusKm;
    }
    for (final order in _orders) {
      _ensureProgressForOrder(order);
      _initializeLedgerForOrder(order);
      if (order.status == OrderStatus.delivered) {
        _releaseSettlement(order);
      }
    }
    _startDeliverySimulation();
  }

  void bindUser(AppUser? user) {
    if (_viewer?.id == user?.id && _viewer?.role == user?.role) {
      return;
    }
    _viewer = user;
    notifyListeners();
  }

  List<Order> get orders => List.unmodifiable(_visibleOrders);
  List<Order> get allOrders => List.unmodifiable(_orders);
  List<AppNotification> get notifications {
    if (_viewer == null) return const [];
    final visible = _notifications
        .where((notification) => notification.recipientUserId == _viewer!.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(visible);
  }

  int get unreadNotificationCount =>
      notifications.where((notification) => !notification.isRead).length;

  List<Order> get activeOrders => _visibleOrders
      .where((order) =>
          order.status != OrderStatus.delivered &&
          order.status != OrderStatus.cancelled)
      .toList();

  List<Order> get pastOrders => _visibleOrders
      .where((order) =>
          order.status == OrderStatus.delivered ||
          order.status == OrderStatus.cancelled)
      .toList();

  List<Order> get pendingDeliveryOrders => _visibleOrders
      .where((order) =>
          order.status == OrderStatus.readyForPickup ||
          order.status == OrderStatus.outForDelivery)
      .toList();

  List<Order> get storeOrders =>
      _visibleOrders.where((order) => order.status != OrderStatus.cancelled).toList();

  Order? getOrder(String id) {
    final matches = _orders.where((order) => order.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  DeliveryFeedback? feedbackForOrder(String orderId) => _feedbackByOrderId[orderId];

  bool shouldPromptCustomerForRating(String orderId) {
    if (_viewer?.role != UserRole.customer) return false;
    final order = getOrder(orderId);
    if (order == null || order.status != OrderStatus.delivered) return false;
    if (_feedbackByOrderId.containsKey(orderId)) return false;
    if (order.customerId != _viewer?.id) return false;
    if (_customerPromptedByOrderId[orderId] == true) return false;
    return true;
  }

  void markCustomerPromptSeen(String orderId) {
    _customerPromptedByOrderId[orderId] = true;
  }

  bool shouldPromptDeliveryPartner(String orderId) {
    if (_viewer?.role != UserRole.delivery) return false;
    final order = getOrder(orderId);
    if (order == null || order.status != OrderStatus.delivered) return false;
    if (order.deliveryPersonId != _viewer?.id) return false;
    if (_deliveryPartnerPromptedByOrderId[orderId] == true) return false;
    return true;
  }

  void markDeliveryPromptSeen(String orderId) {
    _deliveryPartnerPromptedByOrderId[orderId] = true;
  }

  EarningsSummary earningsFor(UserRole role, {String? userId}) {
    final id = userId ?? _viewer?.id ?? '';
    switch (role) {
      case UserRole.customer:
        return const EarningsSummary(
          held: 0,
          released: 0,
          lifetime: 0,
          completedOrders: 0,
        );
      case UserRole.storeOwner:
        final completed = _orders
            .where((order) =>
                order.status == OrderStatus.delivered &&
                _storeForOrder(order).ownerId == id)
            .length;
        final held = _heldStoreEarnings[id] ?? 0;
        final released = _releasedStoreEarnings[id] ?? 0;
        return EarningsSummary(
          held: held,
          released: released,
          lifetime: held + released,
          completedOrders: completed,
        );
      case UserRole.delivery:
        final completed = _orders
            .where((order) =>
                order.status == OrderStatus.delivered &&
                order.deliveryPersonId == id)
            .length;
        final held = _heldDeliveryEarnings[id] ?? 0;
        final released = _releasedDeliveryEarnings[id] ?? 0;
        return EarningsSummary(
          held: held,
          released: released,
          lifetime: held + released,
          completedOrders: completed,
        );
    }
  }

  double get platformHeldBalance =>
      _heldPlatformEarnings.values.fold(0, (sum, value) => sum + value);

  double get platformReleasedBalance =>
      _releasedPlatformEarnings.values.fold(0, (sum, value) => sum + value);

  Map<String, dynamic> get adminSnapshot {
    final completedOrders =
        _orders.where((order) => order.status == OrderStatus.delivered).length;
    final cancelledOrders =
        _orders.where((order) => order.status == OrderStatus.cancelled).length;
    final avgRating = _feedbackByOrderId.isEmpty
        ? 0.0
        : _feedbackByOrderId.values
                .fold<int>(0, (sum, feedback) => sum + feedback.rating) /
            _feedbackByOrderId.length;

    return {
      'totalOrders': _orders.length,
      'completedOrders': completedOrders,
      'cancelledOrders': cancelledOrders,
      'platformHeldBalance': platformHeldBalance,
      'platformReleasedBalance': platformReleasedBalance,
      'deliveryFeedbackCount': _feedbackByOrderId.length,
      'averageDeliveryRating': avgRating,
      'serviceRadiusCount': _serviceRadiusByStoreId.length,
    };
  }

  List<Store> storesServingLocation(LatLng customerLocation) {
    return MockData.stores.where((store) {
      final radiusKm = _serviceRadiusByStoreId[store.id] ?? _defaultServiceRadiusKm;
      final distanceKm =
          _distance.as(LengthUnit.Kilometer, store.location, customerLocation);
      return distanceKm <= radiusKm;
    }).toList();
  }

  double radiusForStore(String storeId) =>
      _serviceRadiusByStoreId[storeId] ?? _defaultServiceRadiusKm;

  void updateStoreRadius(String storeId, double radiusKm) {
    _serviceRadiusByStoreId[storeId] = radiusKm.clamp(1, 15);
    notifyListeners();
  }

  Order placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    required double deliveryFee,
    required String deliveryAddress,
    required LatLng customerLocation,
    required double platformFee,
    required double handlingFee,
    required double deliveryTip,
    required double couponDiscount,
    String? notes,
    String paymentMethod = 'cod',
  }) {
    final customer = _viewer ?? MockData.defaultCustomer;
    final availableStores = storesServingLocation(customerLocation);
    final store = availableStores.isNotEmpty ? availableStores.first : MockData.stores.first;
    final order = Order(
      id: 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      items: items
          .map((item) => CartItem(product: item.product, quantity: item.quantity))
          .toList(),
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
      estimatedDelivery: DateTime.now().add(const Duration(minutes: 28)),
      customerLocation: customerLocation,
      storeLocation: store.location,
      notes: notes,
      paymentMethod: paymentMethod,
      platformFee: platformFee,
      handlingFee: handlingFee,
      deliveryTip: deliveryTip,
      couponDiscount: couponDiscount,
    );
    _orders.insert(0, order);
    _initializeLedgerForOrder(order);
    _pushOrderNotifications(order);
    _ensureProgressForOrder(order);
    notifyListeners();
    return order;
  }

  bool updateOrderStatus(String orderId, OrderStatus status) {
    final order = getOrder(orderId);
    if (order == null || order.status == status) {
      return false;
    }

    if (!_isValidTransition(order.status, status)) {
      return false;
    }

    order.status = status;
    if (status == OrderStatus.outForDelivery) {
      final deliveryPartner = _viewer?.role == UserRole.delivery
          ? _viewer!
          : _assignDeliveryPartner(order);
      order.deliveryPersonId = deliveryPartner.id;
      order.deliveryPersonName = deliveryPartner.name;
      order.deliveryPersonLocation = deliveryPartner.location;
      _createNotification(
        recipientUserId: order.customerId,
        category: 'order',
        title: 'Your order is on the way',
        body: '${deliveryPartner.name} is now delivering order ${order.id}.',
        orderId: order.id,
      );
    }

    if (status == OrderStatus.delivered) {
      _progressTimers.remove(order.id)?.cancel();
      _releaseSettlement(order);
      _createNotification(
        recipientUserId: order.customerId,
        category: 'order',
        title: 'Order delivered',
        body: 'Rate ${order.deliveryPersonName ?? 'your delivery partner'} and review the delivery experience.',
        orderId: order.id,
      );
      if (order.deliveryPersonId != null) {
        _createNotification(
          recipientUserId: order.deliveryPersonId!,
          category: 'earning',
          title: 'Delivery earnings released',
          body: 'Your payout for order ${order.id} is now ready for settlement.',
          orderId: order.id,
        );
      }
    }

    if (status == OrderStatus.cancelled) {
      _progressTimers.remove(order.id)?.cancel();
      _clearHeldSettlement(order);
    }

    notifyListeners();
    return true;
  }

  bool submitDeliveryFeedback({
    required String orderId,
    required int rating,
    required String feedback,
  }) {
    final order = getOrder(orderId);
    final viewer = _viewer;
    if (order == null ||
        viewer == null ||
        viewer.role != UserRole.customer ||
        order.status != OrderStatus.delivered ||
        order.customerId != viewer.id ||
        order.deliveryPersonId == null) {
      return false;
    }

    _feedbackByOrderId[orderId] = DeliveryFeedback(
      orderId: orderId,
      customerId: viewer.id,
      deliveryPersonId: order.deliveryPersonId!,
      rating: rating,
      feedback: feedback.trim(),
      createdAt: DateTime.now(),
    );
    _createNotification(
      recipientUserId: order.deliveryPersonId!,
      category: 'system',
      title: 'New delivery feedback',
      body: 'You received a $rating-star rating for order ${order.id}.',
      orderId: order.id,
    );
    notifyListeners();
    return true;
  }

  void markNotificationRead(String notificationId) {
    final notification = _notifications.where((item) => item.id == notificationId);
    if (notification.isEmpty) return;
    notification.first.isRead = true;
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
        return _orders
            .where((order) => _storeForOrder(order).ownerId == _viewer!.id)
            .toList();
      case UserRole.delivery:
        return _orders.where((order) {
          return order.status == OrderStatus.readyForPickup ||
              order.deliveryPersonId == _viewer!.id;
        }).toList();
    }
  }

  bool _isValidTransition(OrderStatus current, OrderStatus next) {
    if (current == OrderStatus.cancelled || current == OrderStatus.delivered) {
      return false;
    }
    const transitions = {
      OrderStatus.placed: [OrderStatus.confirmed, OrderStatus.cancelled],
      OrderStatus.confirmed: [OrderStatus.preparing, OrderStatus.cancelled],
      OrderStatus.preparing: [OrderStatus.readyForPickup, OrderStatus.cancelled],
      OrderStatus.readyForPickup: [OrderStatus.outForDelivery],
      OrderStatus.outForDelivery: [OrderStatus.delivered],
    };
    return transitions[current]?.contains(next) ?? false;
  }

  void _ensureProgressForOrder(Order order) {
    if (_progressTimers.containsKey(order.id) ||
        order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled ||
        order.status == OrderStatus.outForDelivery) {
      return;
    }

    _progressTimers[order.id] =
        Timer.periodic(const Duration(seconds: 8), (timer) {
      if (order.status == OrderStatus.cancelled ||
          order.status == OrderStatus.delivered) {
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
          _createNotification(
            recipientUserId: order.customerId,
            category: 'order',
            title: 'Packed and ready',
            body: '${order.storeName} has packed order ${order.id}. A delivery partner will pick it up shortly.',
            orderId: order.id,
          );
          break;
        case OrderStatus.readyForPickup:
          final deliveryPartner = _assignDeliveryPartner(order);
          order.status = OrderStatus.outForDelivery;
          order.deliveryPersonId = deliveryPartner.id;
          order.deliveryPersonName = deliveryPartner.name;
          order.deliveryPersonLocation = deliveryPartner.location;
          _createNotification(
            recipientUserId: order.customerId,
            category: 'order',
            title: 'Rider assigned',
            body: '${deliveryPartner.name} has picked up order ${order.id}.',
            orderId: order.id,
          );
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
        if (order.status == OrderStatus.outForDelivery &&
            order.deliveryPersonLocation != null) {
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
            _releaseSettlement(order);
            _createNotification(
              recipientUserId: order.customerId,
              category: 'order',
              title: 'Delivered successfully',
              body: 'Order ${order.id} arrived. Please rate your rider.',
              orderId: order.id,
            );
          }
          changed = true;
        }
      }
      if (changed) {
        notifyListeners();
      }
    });
  }

  void _initializeLedgerForOrder(Order order) {
    if (_settlementReleasedByOrderId.containsKey(order.id)) {
      return;
    }

    final store = _storeForOrder(order);
    final deliveryPartner = order.deliveryPersonId == null
        ? null
        : MockData.deliveryPersons.firstWhere(
            (partner) => partner.id == order.deliveryPersonId,
            orElse: () => MockData.deliveryPersons.first,
          );
    final platformShare = _platformShare(order);
    final deliveryShare = _deliveryShare(order);
    final storeShare = _storeShare(order);

    _heldPlatformEarnings[order.id] = platformShare;
    _heldStoreEarnings[store.ownerId] =
        (_heldStoreEarnings[store.ownerId] ?? 0) + storeShare;
    if (deliveryPartner != null) {
      _heldDeliveryEarnings[deliveryPartner.id] =
          (_heldDeliveryEarnings[deliveryPartner.id] ?? 0) + deliveryShare;
    }
    _settlementReleasedByOrderId[order.id] = false;
  }

  void _releaseSettlement(Order order) {
    if (_settlementReleasedByOrderId[order.id] == true) {
      return;
    }

    final store = _storeForOrder(order);
    final deliveryPartnerId = order.deliveryPersonId;
    final platformHeld = _heldPlatformEarnings.remove(order.id) ?? 0;
    final storeShare = _storeShare(order);
    final deliveryShare = _deliveryShare(order);

    _releasedPlatformEarnings[order.id] =
        (_releasedPlatformEarnings[order.id] ?? 0) + platformHeld;

    _heldStoreEarnings[store.ownerId] =
        ((_heldStoreEarnings[store.ownerId] ?? 0) - storeShare).clamp(0, double.infinity);
    _releasedStoreEarnings[store.ownerId] =
        (_releasedStoreEarnings[store.ownerId] ?? 0) + storeShare;

    if (deliveryPartnerId != null) {
      _heldDeliveryEarnings[deliveryPartnerId] =
          ((_heldDeliveryEarnings[deliveryPartnerId] ?? 0) - deliveryShare)
              .clamp(0, double.infinity);
      _releasedDeliveryEarnings[deliveryPartnerId] =
          (_releasedDeliveryEarnings[deliveryPartnerId] ?? 0) + deliveryShare;
    }

    _settlementReleasedByOrderId[order.id] = true;
  }

  void _clearHeldSettlement(Order order) {
    final store = _storeForOrder(order);
    final storeShare = _storeShare(order);
    final deliveryShare = _deliveryShare(order);

    _heldPlatformEarnings.remove(order.id);
    _heldStoreEarnings[store.ownerId] =
        ((_heldStoreEarnings[store.ownerId] ?? 0) - storeShare).clamp(0, double.infinity);
    if (order.deliveryPersonId != null) {
      _heldDeliveryEarnings[order.deliveryPersonId!] =
          ((_heldDeliveryEarnings[order.deliveryPersonId!] ?? 0) - deliveryShare)
              .clamp(0, double.infinity);
    }
    _settlementReleasedByOrderId[order.id] = false;
  }

  void _pushOrderNotifications(Order order) {
    _createNotification(
      recipientUserId: order.customerId,
      category: 'order',
      title: 'Order placed',
      body: 'We have forwarded order ${order.id} to ${order.storeName}.',
      orderId: order.id,
    );

    final store = _storeForOrder(order);
    _createNotification(
      recipientUserId: store.ownerId,
      category: 'order',
      title: 'New order received',
      body: 'Customer ${order.customerName} placed order ${order.id}.',
      orderId: order.id,
    );
  }

  void _createNotification({
    required String recipientUserId,
    required String category,
    required String title,
    required String body,
    String? orderId,
  }) {
    _notifications.insert(
      0,
      AppNotification(
        id: 'NTF${DateTime.now().microsecondsSinceEpoch}',
        recipientUserId: recipientUserId,
        title: title,
        body: body,
        category: category,
        createdAt: DateTime.now(),
        orderId: orderId,
      ),
    );
  }

  AppUser _assignDeliveryPartner(Order order) {
    final nearest = [...MockData.deliveryPersons]
      ..sort((a, b) {
        final distanceA =
            _distance.as(LengthUnit.Kilometer, a.location, order.storeLocation);
        final distanceB =
            _distance.as(LengthUnit.Kilometer, b.location, order.storeLocation);
        return distanceA.compareTo(distanceB);
      });
    return nearest.first;
  }

  Store _storeForOrder(Order order) {
    return MockData.stores.firstWhere(
      (store) => store.id == order.storeId,
      orElse: () => MockData.stores.first,
    );
  }

  double _basketSubtotal(Order order) {
    return order.items.fold<double>(0, (sum, item) => sum + item.totalPrice);
  }

  double _platformShare(Order order) {
    return (_basketSubtotal(order) * _platformCommissionRate) +
        order.platformFee +
        order.handlingFee;
  }

  double _deliveryShare(Order order) {
    return order.deliveryFee + order.deliveryTip;
  }

  double _storeShare(Order order) {
    final share = order.grandTotal - _platformShare(order) - _deliveryShare(order);
    return share < 0 ? 0 : share;
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
