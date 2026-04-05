import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/order_card.dart';
import 'delivery_detail_screen.dart';

class DeliveryDashboardScreen extends StatelessWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Dashboard', style: TextStyle(fontSize: 18)),
            Text('Online', style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                SizedBox(width: 6),
                Text('Active', style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<OrderService>(
        builder: (context, orderService, _) {
          final availableOrders = orderService.orders
              .where((o) =>
                  o.status == OrderStatus.readyForPickup ||
                  o.status == OrderStatus.outForDelivery)
              .toList();

          final completedToday = orderService.orders
              .where((o) => o.status == OrderStatus.delivered)
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Available',
                        '${availableOrders.length}',
                        Icons.local_shipping,
                        AppTheme.primaryRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Completed Today',
                        '$completedToday',
                        Icons.done_all,
                        AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Earnings',
                        'â‚¹${completedToday * 50}',
                        Icons.currency_rupee,
                        AppTheme.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Available orders
                const Text(
                  'Available Orders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick up ready orders and keep customers updated',
                  style: TextStyle(color: AppTheme.textMedium, fontSize: 13),
                ),
                const SizedBox(height: 12),

                if (availableOrders.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.delivery_dining, size: 64, color: AppTheme.textLight),
                          SizedBox(height: 12),
                          Text('No orders available', style: TextStyle(color: AppTheme.textMedium, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('New orders will appear here', style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else
                  ...availableOrders.map((order) => OrderCard(
                        order: order,
                        showActions: true,
                        onAccept: () {
                          final nextStatus = order.status == OrderStatus.readyForPickup
                              ? OrderStatus.outForDelivery
                              : OrderStatus.delivered;
                          orderService.updateOrderStatus(
                            order.id,
                            nextStatus,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                nextStatus == OrderStatus.outForDelivery
                                    ? 'Order picked up! Start delivering.'
                                    : 'Order marked as delivered!',
                              ),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        },
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeliveryDetailScreen(order: order),
                          ),
                        ),
                      )),

                const SizedBox(height: 24),

                // All orders
                const Text(
                  'Recent Deliveries',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...orderService.orders
                    .where((o) => o.status == OrderStatus.delivered)
                    .map((order) => OrderCard(order: order)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppTheme.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: AppTheme.textMedium, fontSize: 11)),
        ],
      ),
    );
  }
}

