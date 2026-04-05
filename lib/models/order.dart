import 'package:latlong2/latlong.dart';
import 'cart_item.dart';

enum OrderStatus {
  placed,
  confirmed,
  preparing,
  readyForPickup,
  outForDelivery,
  delivered,
  cancelled,
}

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final double deliveryFee;
  final double platformFee;
  final double handlingFee;
  final double deliveryTip;
  final double couponDiscount;
  OrderStatus status;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String storeId;
  final String storeName;
  String? deliveryPersonId;
  String? deliveryPersonName;
  final String deliveryAddress;
  final DateTime placedAt;
  final DateTime estimatedDelivery;
  final LatLng customerLocation;
  final LatLng storeLocation;
  LatLng? deliveryPersonLocation;
  final String? notes;
  final String paymentMethod;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    this.deliveryFee = 29.0,
    this.platformFee = 0,
    this.handlingFee = 0,
    this.deliveryTip = 0,
    this.couponDiscount = 0,
    this.status = OrderStatus.placed,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.storeId,
    required this.storeName,
    this.deliveryPersonId,
    this.deliveryPersonName,
    required this.deliveryAddress,
    required this.placedAt,
    required this.estimatedDelivery,
    required this.customerLocation,
    required this.storeLocation,
    this.deliveryPersonLocation,
    this.notes,
    this.paymentMethod = 'cod',
  });

  double get grandTotal =>
      totalAmount + deliveryFee + platformFee + handlingFee + deliveryTip - couponDiscount;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get statusLabel {
    switch (status) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  double get statusProgress {
    switch (status) {
      case OrderStatus.placed:
        return 0.15;
      case OrderStatus.confirmed:
        return 0.3;
      case OrderStatus.preparing:
        return 0.5;
      case OrderStatus.readyForPickup:
        return 0.65;
      case OrderStatus.outForDelivery:
        return 0.8;
      case OrderStatus.delivered:
        return 1.0;
      case OrderStatus.cancelled:
        return 0.0;
    }
  }
}
