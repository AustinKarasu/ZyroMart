import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/order_card.dart';
import 'delivery_detail_screen.dart';

class DeliveryDashboardScreen extends StatelessWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final rider = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F2),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delivery Command', style: TextStyle(fontSize: 18)),
            Text(
              rider?.isOnline == true ? 'Online and dispatch-ready' : 'Offline',
              style: const TextStyle(fontSize: 12, color: Colors.greenAccent),
            ),
          ],
        ),
        actions: [
          Consumer<OrderService>(
            builder: (context, orders, _) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${orders.unreadNotificationCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<OrderService>(
        builder: (context, orderService, _) {
          final availableOrders = orderService.allOrders
              .where((order) =>
                  order.status == OrderStatus.readyForPickup ||
                  (order.status == OrderStatus.outForDelivery &&
                      order.deliveryPersonId == rider?.id))
              .toList();
          final earnings = orderService.earningsFor(UserRole.delivery);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Available',
                      '${availableOrders.length}',
                      Icons.local_shipping_outlined,
                      const Color(0xFFCC3A2D),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Held',
                      'Rs ${earnings.held.toInt()}',
                      Icons.lock_clock_outlined,
                      const Color(0xFFD4830D),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Released',
                      'Rs ${earnings.released.toInt()}',
                      Icons.account_balance_wallet_outlined,
                      const Color(0xFF1D8C3A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settlement logic',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Delivery earnings stay on hold until the order reaches delivered status. Once completed, the rider share becomes released and visible here.',
                      style: TextStyle(
                        color: AppTheme.textMedium,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${earnings.completedOrders} completed deliveries tracked in this session',
                      style: const TextStyle(
                        color: AppTheme.primaryRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFFD8D2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBE342A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.emergency_outlined,
                        color: Color(0xFFBE342A),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency help',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Use this when a handoff feels unsafe or you need urgent dispatch support.',
                            style: TextStyle(
                              color: AppTheme.textMedium,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Dispatch support alert logged for this rider session.',
                            ),
                            backgroundColor: AppTheme.primaryRed,
                          ),
                        );
                      },
                      child: const Text('Alert'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pickup and delivery queue',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (availableOrders.isEmpty)
                _EmptyDeliveryState()
              else
                ...availableOrders.map(
                  (order) => OrderCard(
                    order: order,
                    showActions: true,
                    onAccept: () {
                      final nextStatus = order.status == OrderStatus.readyForPickup
                          ? OrderStatus.outForDelivery
                          : OrderStatus.delivered;
                      final success =
                          orderService.updateOrderStatus(order.id, nextStatus);
                      final message = success
                          ? (nextStatus == OrderStatus.outForDelivery
                              ? 'Pickup confirmed. Navigate to customer.'
                              : 'Delivery complete. Earnings are now released.')
                          : 'This order cannot move to that state yet.';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor:
                              success ? AppTheme.success : AppTheme.primaryRed,
                        ),
                      );
                    },
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeliveryDetailScreen(order: order),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              const Text(
                'Recent deliveries',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ...orderService.allOrders
                  .where((order) =>
                      order.status == OrderStatus.delivered &&
                      order.deliveryPersonId == rider?.id)
                  .map((order) => OrderCard(order: order)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textMedium)),
        ],
      ),
    );
  }
}

class _EmptyDeliveryState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(Icons.delivery_dining_rounded,
              size: 62, color: AppTheme.textLight),
          SizedBox(height: 14),
          Text(
            'No active tasks right now',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'New ready-for-pickup orders will appear here automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMedium, height: 1.4),
          ),
        ],
      ),
    );
  }
}
