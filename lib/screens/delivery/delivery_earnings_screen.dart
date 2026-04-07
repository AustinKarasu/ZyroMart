import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';

class DeliveryEarningsScreen extends StatelessWidget {
  final AppUser? user;
  const DeliveryEarningsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final orderService = context.watch<OrderService>();
    final rider = user ?? auth.currentUser;
    if (rider == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    final earnings = orderService.earningsFor(
      UserRole.delivery,
      userId: rider.id,
    );
    final completedOrders =
        orderService.allOrders
            .where(
              (o) =>
                  o.deliveryPersonId == rider.id &&
                  o.status == OrderStatus.delivered,
            )
            .toList()
          ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      appBar: AppBar(title: const Text('Earnings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Total Earned',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs ${(earnings.held + earnings.released).toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _earningStat(
                      'Rs ${earnings.released.toInt()}',
                      'Released',
                      Icons.check_circle_outline,
                    ),
                    const SizedBox(width: 1),
                    Container(width: 1, height: 40, color: Colors.white24),
                    const SizedBox(width: 1),
                    _earningStat(
                      'Rs ${earnings.held.toInt()}',
                      'Pending',
                      Icons.hourglass_empty,
                    ),
                    const SizedBox(width: 1),
                    Container(width: 1, height: 40, color: Colors.white24),
                    const SizedBox(width: 1),
                    _earningStat(
                      '${rider.completedDeliveries ?? completedOrders.length}',
                      'Trips',
                      Icons.two_wheeler,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Per-delivery breakdown
          const Text(
            'Delivery History',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 10),
          if (completedOrders.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.delivery_dining,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No completed deliveries yet',
                    style: TextStyle(
                      color: AppTheme.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Completed trips will appear here',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ...completedOrders.map((order) {
              final perDelivery = order.totalAmount * 0.12; // 12% delivery cut
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: AppTheme.cardShadow,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppTheme.success,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.id.substring(0, 8).toUpperCase()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${order.items.length} item${order.items.length == 1 ? '' : 's'} • Rs ${order.totalAmount.toInt()} order value',
                            style: const TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+ Rs ${perDelivery.toInt()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.success,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _earningStat(String value, String label, IconData icon) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    ),
  );
}
