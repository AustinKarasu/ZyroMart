import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #$orderId')),
      body: Consumer<OrderService>(
        builder: (context, orderService, _) {
          final order = orderService.getOrder(orderId);
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }
          return Column(
            children: [
              // Map
              Expanded(
                flex: 3,
                child: _buildMap(order),
              ),
              // Order details
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  child: _buildOrderDetails(order),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(Order order) {
    final markers = <Marker>[
      // Store location
      Marker(
        point: order.storeLocation,
        width: 40,
        height: 40,
        child: const Icon(Icons.store, color: AppTheme.primaryRed, size: 36),
      ),
      // Customer location
      Marker(
        point: order.customerLocation,
        width: 40,
        height: 40,
        child: const Icon(Icons.home, color: AppTheme.info, size: 36),
      ),
    ];

    // Delivery person location
    if (order.deliveryPersonLocation != null &&
        order.status == OrderStatus.outForDelivery) {
      markers.add(
        Marker(
          point: order.deliveryPersonLocation!,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryRed,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.delivery_dining,
                color: Colors.white, size: 24),
          ),
        ),
      );
    }

    final center = order.deliveryPersonLocation ?? order.storeLocation;

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.zyromart.app',
        ),
        // Route line
        if (order.status == OrderStatus.outForDelivery &&
            order.deliveryPersonLocation != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  order.storeLocation,
                  order.deliveryPersonLocation!,
                  order.customerLocation,
                ],
                color: AppTheme.primaryRed.withValues(alpha: 0.7),
                strokeWidth: 3,
                pattern: const StrokePattern.dotted(),
              ),
            ],
          ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildOrderDetails(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Status
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon(order.status),
                  color: _statusColor(order.status),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.statusLabel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _statusColor(order.status),
                      ),
                    ),
                    Text(
                      _statusDescription(order.status),
                      style: TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: order.statusProgress,
              backgroundColor: Colors.grey[200],
              valueColor:
                  AlwaysStoppedAnimation<Color>(_statusColor(order.status)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Placed', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
              Text('Delivered', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
            ],
          ),
          const SizedBox(height: 20),
          // Delivery person info
          if (order.deliveryPersonName != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryRed,
                    child: Text(
                      order.deliveryPersonName![0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.deliveryPersonName!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Delivery Partner',
                          style: TextStyle(
                              color: AppTheme.textMedium, fontSize: 12),
                        ),
                        const Text(
                          'Phone verified for delivery updates',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone, color: AppTheme.primaryRed),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Delivery address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on,
                  color: AppTheme.primaryRed, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      order.deliveryAddress,
                      style: TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Items
          const Text(
            'Items Ordered',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.product.name} x${item.quantity}'),
                    Text('₹${item.totalPrice.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              )),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('₹${order.grandTotal.toInt()}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryRed)),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return AppTheme.info;
      case OrderStatus.confirmed:
        return Colors.indigo;
      case OrderStatus.preparing:
        return AppTheme.warning;
      case OrderStatus.readyForPickup:
        return Colors.deepPurple;
      case OrderStatus.outForDelivery:
        return AppTheme.primaryRed;
      case OrderStatus.delivered:
        return AppTheme.success;
      case OrderStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return Icons.receipt_long;
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.readyForPickup:
        return Icons.inventory;
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _statusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Your order has been placed successfully';
      case OrderStatus.confirmed:
        return 'Store has confirmed your order';
      case OrderStatus.preparing:
        return 'Your order is being prepared';
      case OrderStatus.readyForPickup:
        return 'Order is ready for pickup by delivery partner';
      case OrderStatus.outForDelivery:
        return 'Your order is on the way!';
      case OrderStatus.delivered:
        return 'Order has been delivered';
      case OrderStatus.cancelled:
        return 'Order was cancelled';
    }
  }
}
