import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class StoreAnalyticsScreen extends StatelessWidget {
  const StoreAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final orderService = context.watch<OrderService>();
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>?>(
      future: SupabaseService.isInitialized
          ? SupabaseService.getStoreByOwner(user.id)
          : Future.value(null),
      builder: (context, snap) {
        final storeId = (snap.data?['id'] ?? '').toString();
        final storeOrders = orderService.allOrders
            .where((o) => o.storeId == storeId)
            .toList();

        final totalOrders = storeOrders.length;
        final completedOrders = storeOrders.where((o) => o.status == OrderStatus.delivered).length;
        final cancelledOrders = storeOrders.where((o) => o.status == OrderStatus.cancelled).length;
        final activeOrders = storeOrders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).length;
        final revenue = storeOrders
            .where((o) => o.status == OrderStatus.delivered)
            .fold(0.0, (sum, o) => sum + o.totalAmount);
        final earnings = orderService.earningsFor(UserRole.storeOwner, userId: user.id);
        final avgOrderValue = completedOrders > 0 ? revenue / completedOrders : 0.0;

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FA),
          appBar: AppBar(
            title: const Text('Analytics'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => orderService.bindUser(user),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => orderService.bindUser(user),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Revenue Summary
                _sectionHeader('Revenue Summary'),
                Row(
                  children: [
                    Expanded(child: _metricCard('Total Revenue', 'Rs ${revenue.toInt()}', Icons.currency_rupee, AppTheme.success)),
                    const SizedBox(width: 12),
                    Expanded(child: _metricCard('Held', 'Rs ${earnings.held.toInt()}', Icons.hourglass_bottom, AppTheme.warning)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _metricCard('Released', 'Rs ${earnings.released.toInt()}', Icons.account_balance_wallet, AppTheme.info)),
                    const SizedBox(width: 12),
                    Expanded(child: _metricCard('Avg Order', 'Rs ${avgOrderValue.toInt()}', Icons.shopping_bag_outlined, AppTheme.primaryRed)),
                  ],
                ),
                const SizedBox(height: 20),

                // Order Stats
                _sectionHeader('Order Statistics'),
                Row(
                  children: [
                    Expanded(child: _metricCard('Total', '$totalOrders', Icons.receipt_long, Colors.blueGrey)),
                    const SizedBox(width: 12),
                    Expanded(child: _metricCard('Active', '$activeOrders', Icons.pending_actions, AppTheme.info)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _metricCard('Completed', '$completedOrders', Icons.check_circle_outline, AppTheme.success)),
                    const SizedBox(width: 12),
                    Expanded(child: _metricCard('Cancelled', '$cancelledOrders', Icons.cancel_outlined, AppTheme.primaryRed)),
                  ],
                ),
                const SizedBox(height: 20),

                // Completion rate bar
                if (totalOrders > 0) ...[
                  _sectionHeader('Completion Rate'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Success Rate', style: TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              '${(completedOrders / totalOrders * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.success, fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: completedOrders / totalOrders,
                            backgroundColor: const Color(0xFFF0F0F0),
                            color: AppTheme.success,
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$completedOrders delivered out of $totalOrders total orders',
                          style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Recent orders
                _sectionHeader('Recent Orders'),
                if (storeOrders.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: const Text('No orders yet. They will appear here once customers start ordering.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMedium)),
                  )
                else
                  ...storeOrders.take(10).map((order) => _orderRow(order)),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textMedium, letterSpacing: 0.5)),
  );

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: AppTheme.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textLight, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _orderRow(Order order) {
    Color statusColor;
    switch (order.status) {
      case OrderStatus.delivered: statusColor = AppTheme.success; break;
      case OrderStatus.cancelled: statusColor = AppTheme.primaryRed; break;
      case OrderStatus.outForDelivery: statusColor = AppTheme.info; break;
      default: statusColor = AppTheme.warning;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${order.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(order.status.name.replaceAll(RegExp(r'(?<=[a-z])(?=[A-Z])'), ' '), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text('Rs ${order.totalAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      ),
    );
  }
}
