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
import 'supabase_service.dart';

class OrderService extends ChangeNotifier {
  static const double _platformCommissionRate = 0.05;
  static const double _defaultServiceRadiusKm = 5;

  final Distance _distance = const Distance();
  final List<Order> _orders = [];
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
  final Map<String, String> _completionCodes = {};
  final Map<String, List<Map<String, dynamic>>> _statusEventsByOrderId = {};
  final Map<String, List<Map<String, dynamic>>> _inventoryReservationsByOrderId = {};
  final Map<String, Map<String, dynamic>> _proofOfDeliveryByOrderId = {};
  AppUser? _viewer;

  OrderService() {
    _orders.addAll(MockData.sampleOrders);
    for (final store in MockData.stores) {
      _serviceRadiusByStoreId[store.id] = _defaultServiceRadiusKm;
    }
    for (final order in _orders) {
      _completionCodes[order.id] = order.deliveryVerificationCode;
      _initializeLedgerForOrder(order);
      if (order.status == OrderStatus.delivered) {
        _releaseSettlement(order);
      }
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

  bool canCustomerCancel(Order order) {
    if (_viewer?.role != UserRole.customer || _viewer?.id != order.customerId) {
      return false;
    }
    if (order.status != OrderStatus.placed && order.status != OrderStatus.confirmed) {
      return false;
    }
    return DateTime.now().difference(order.placedAt) <= const Duration(minutes: 5);
  }

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
    final verificationCode = _generateDeliveryCode();
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
      deliveryVerificationCode: verificationCode,
    );
    _orders.insert(0, order);
    _completionCodes[order.id] = verificationCode;
    _initializeLedgerForOrder(order);
    _reserveInventory(order);
    _recordStatusEvent(
      order: order,
      previousStatus: null,
      nextStatus: OrderStatus.placed,
      notes: 'Order created and forwarded to the store.',
    );
    _pushOrderNotifications(order);
    notifyListeners();
    return order;
  }

  String? deliveryCodeForCustomer(String orderId) {
    final order = getOrder(orderId);
    if (order == null || _viewer?.id != order.customerId) return null;
    return _completionCodes[orderId];
  }

  bool updateOrderStatus(String orderId, OrderStatus status) {
    final order = getOrder(orderId);
    if (order == null || order.status == status) {
      return false;
    }

    final previousStatus = order.status;

    if (!_isValidTransition(previousStatus, status)) {
      return false;
    }

    order.status = status;
    _recordStatusEvent(
      order: order,
      previousStatus: previousStatus,
      nextStatus: status,
      notes: _statusEventNote(status),
    );
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
      _createNotification(
        recipientUserId: deliveryPartner.id,
        category: 'order',
        title: 'Proceed to customer',
        body: 'Collect OTP from ${order.customerName} to complete order ${order.id}.',
        orderId: order.id,
      );
    }

    if (status == OrderStatus.delivered) {
      _captureProofOfDelivery(order);
      _consumeInventory(order.id);
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
      _releaseInventory(order.id);
      _clearHeldSettlement(order);
    }

    _notifyStatusChange(order);

    notifyListeners();
    return true;
  }

  bool completeDeliveryWithCode(String orderId, String code) {
    final order = getOrder(orderId);
    if (order == null ||
        order.status != OrderStatus.outForDelivery ||
        order.deliveryPersonId != _viewer?.id) {
      return false;
    }
    final expected = _completionCodes[orderId];
    if (expected == null || expected != code.trim()) {
      return false;
    }
    return updateOrderStatus(orderId, OrderStatus.delivered);
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

  bool cancelOrder(String orderId) {
    final order = getOrder(orderId);
    if (order == null || !canCustomerCancel(order)) {
      return false;
    }

    final previousStatus = order.status;
    order.status = OrderStatus.cancelled;
    _recordStatusEvent(
      order: order,
      previousStatus: previousStatus,
      nextStatus: OrderStatus.cancelled,
      notes: 'Cancelled by customer inside the grace period.',
    );
    _releaseInventory(order.id);
    _clearHeldSettlement(order);
    _createNotification(
      recipientUserId: order.customerId,
      category: 'order',
      title: 'Order cancelled',
      body: 'Order ${order.id} was cancelled within the allowed window.',
      orderId: order.id,
    );
    final store = _storeForOrder(order);
    _createNotification(
      recipientUserId: store.ownerId,
      category: 'order',
      title: 'Order cancelled by customer',
      body: 'Order ${order.id} was cancelled before fulfillment.',
      orderId: order.id,
    );
    notifyListeners();
    return true;
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

  void _notifyStatusChange(Order order) {
    _createNotification(
      recipientUserId: order.customerId,
      category: 'order',
      title: order.statusLabel,
      body: 'Order ${order.id} is now ${order.statusLabel.toLowerCase()}.',
      orderId: order.id,
    );

    final store = _storeForOrder(order);
    _createNotification(
      recipientUserId: store.ownerId,
      category: 'order',
      title: 'Order ${order.statusLabel}',
      body: 'Order ${order.id} changed to ${order.statusLabel.toLowerCase()}.',
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

  String _generateDeliveryCode() {
    final value = DateTime.now().microsecondsSinceEpoch % 9000;
    return (1000 + value).toString();
  }

  List<Map<String, dynamic>> statusEventsForOrder(String orderId) {
    final events = _statusEventsByOrderId[orderId] ?? const [];
    return List.unmodifiable(events);
  }

  List<Map<String, dynamic>> inventoryReservationsForOrder(String orderId) {
    final reservations = _inventoryReservationsByOrderId[orderId] ?? const [];
    return List.unmodifiable(reservations);
  }

  Map<String, dynamic>? proofOfDeliveryForOrder(String orderId) =>
      _proofOfDeliveryByOrderId[orderId];

  void _recordStatusEvent({
    required Order order,
    required OrderStatus? previousStatus,
    required OrderStatus nextStatus,
    required String notes,
  }) {
    final event = <String, dynamic>{
      'id': 'EVT${DateTime.now().microsecondsSinceEpoch}',
      'order_id': order.id,
      'actor_user_id': _viewer?.id,
      'actor_role': _viewer == null ? 'system' : _actorRole(_viewer!.role),
      'previous_status': previousStatus?.name,
      'next_status': nextStatus.name,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    };
    final bucket = _statusEventsByOrderId.putIfAbsent(order.id, () => []);
    bucket.insert(0, event);
    if (SupabaseService.isInitialized) {
      SupabaseService.insertOrderStatusEvent(event).catchError((_) {});
    }
  }

  void _reserveInventory(Order order) {
    final reservations = order.items
        .map(
          (item) => <String, dynamic>{
            'id': 'RSV${DateTime.now().microsecondsSinceEpoch}${item.product.id}',
            'order_id': order.id,
            'product_id': item.product.id,
            'store_id': order.storeId,
            'reserved_quantity': item.quantity,
            'reservation_status': 'reserved',
            'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        )
        .toList();
    _inventoryReservationsByOrderId[order.id] = reservations;
    if (SupabaseService.isInitialized) {
      SupabaseService.reserveInventory(reservations).catchError((_) {});
    }
  }

  void _releaseInventory(String orderId) {
    final reservations = _inventoryReservationsByOrderId[orderId];
    if (reservations == null) return;
    for (final reservation in reservations) {
      reservation['reservation_status'] = 'released';
      reservation['released_at'] = DateTime.now().toIso8601String();
    }
    if (SupabaseService.isInitialized) {
      SupabaseService.updateInventoryReservationStatus(
        orderId: orderId,
        status: 'released',
      ).catchError((_) {});
    }
  }

  void _consumeInventory(String orderId) {
    final reservations = _inventoryReservationsByOrderId[orderId];
    if (reservations == null) return;
    for (final reservation in reservations) {
      reservation['reservation_status'] = 'consumed';
    }
    if (SupabaseService.isInitialized) {
      SupabaseService.updateInventoryReservationStatus(
        orderId: orderId,
        status: 'consumed',
      ).catchError((_) {});
    }
  }

  void _captureProofOfDelivery(Order order) {
    final proof = <String, dynamic>{
      'order_id': order.id,
      'delivery_person_id': order.deliveryPersonId,
      'handed_to_name': order.customerName,
      'otp_verified': true,
      'notes': order.notes,
      'delivered_at': DateTime.now().toIso8601String(),
    };
    _proofOfDeliveryByOrderId[order.id] = proof;
    if (SupabaseService.isInitialized) {
      SupabaseService.saveProofOfDelivery(proof).catchError((_) {});
    }
  }

  String _actorRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'customer';
      case UserRole.storeOwner:
        return 'store_owner';
      case UserRole.delivery:
        return 'delivery';
    }
  }

  String _statusEventNote(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Order placed successfully.';
      case OrderStatus.confirmed:
        return 'Store confirmed the order.';
      case OrderStatus.preparing:
        return 'Items are being packed and prepared.';
      case OrderStatus.readyForPickup:
        return 'Order is ready for the delivery partner pickup.';
      case OrderStatus.outForDelivery:
        return 'Delivery partner collected the order and is en route.';
      case OrderStatus.delivered:
        return 'Delivery completed after OTP verification.';
      case OrderStatus.cancelled:
        return 'Order was cancelled.';
    }
  }

}
