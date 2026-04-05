import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';

class DeliveryDetailScreen extends StatelessWidget {
  final Order order;

  const DeliveryDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Delivery #${order.id}')),
      body: Consumer<OrderService>(
        builder: (context, orderService, _) {
          final currentOrder = orderService.getOrder(order.id) ?? order;
          return Column(
            children: [
              // Map
              Expanded(
                flex: 2,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: currentOrder.storeLocation,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.zyromart.app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [
                            currentOrder.storeLocation,
                            if (currentOrder.deliveryPersonLocation != null)
                              currentOrder.deliveryPersonLocation!,
                            currentOrder.customerLocation,
                          ],
                          color: AppTheme.primaryRed,
                          strokeWidth: 3,
                          pattern: const StrokePattern.dotted(),
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: currentOrder.storeLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.store, color: AppTheme.primaryRed, size: 36),
                        ),
                        Marker(
                          point: currentOrder.customerLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.home, color: AppTheme.info, size: 36),
                        ),
                        if (currentOrder.deliveryPersonLocation != null)
                          Marker(
                            point: currentOrder.deliveryPersonLocation!,
                            width: 44,
                            height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRed,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(Icons.delivery_dining, color: Colors.white, size: 24),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Order info
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: AppTheme.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('#${currentOrder.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                Text(currentOrder.statusLabel,
                                    style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 24),
                            // Pickup
                            _buildLocationRow(
                              Icons.store,
                              'Pickup from',
                              currentOrder.storeName,
                              '123 Main Street, Sector 15',
                              AppTheme.primaryRed,
                            ),
                            const SizedBox(height: 16),
                            // Drop-off
                            _buildLocationRow(
                              Icons.location_on,
                              'Deliver to',
                              currentOrder.customerName,
                              currentOrder.deliveryAddress,
                              AppTheme.info,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Items
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order Items (${currentOrder.itemCount})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            ...currentOrder.items.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${item.product.name} x${item.quantity}'),
                                      Text('₹${item.totalPrice.toInt()}'),
                                    ],
                                  ),
                                )),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('₹${currentOrder.grandTotal.toInt()}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
                              ],
                            ),
                            if (currentOrder.notes != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.note, color: AppTheme.warning, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(currentOrder.notes!, style: const TextStyle(fontSize: 13))),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Customer contact
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryRed,
                              child: Text(currentOrder.customerName[0], style: const TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(currentOrder.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(currentOrder.customerPhone, style: const TextStyle(color: AppTheme.textMedium, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone, color: AppTheme.primaryRed),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.message, color: AppTheme.primaryRed),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<OrderService>(
        builder: (context, orderService, _) {
          final currentOrder = orderService.getOrder(order.id) ?? order;
          if (currentOrder.status == OrderStatus.delivered ||
              currentOrder.status == OrderStatus.cancelled) {
            return const SizedBox.shrink();
          }
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final nextStatus = currentOrder.status == OrderStatus.readyForPickup
                      ? OrderStatus.outForDelivery
                      : OrderStatus.delivered;
                  orderService.updateOrderStatus(currentOrder.id, nextStatus);
                  if (nextStatus == OrderStatus.delivered) {
                    Navigator.pop(context);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        nextStatus == OrderStatus.outForDelivery
                            ? 'Order picked up! Navigate to customer.'
                            : 'Order delivered successfully!',
                      ),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                },
                child: Text(
                  currentOrder.status == OrderStatus.readyForPickup
                      ? 'Pick Up Order'
                      : 'Mark as Delivered',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationRow(
      IconData icon, String label, String name, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(address, style: TextStyle(color: AppTheme.textMedium, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
