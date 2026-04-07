import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/order_card.dart';
import 'order_tracking_screen.dart';

class CustomerOrdersScreen extends StatelessWidget {
  const CustomerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: Consumer<OrderService>(
        builder: (context, orderService, _) {
          if (orderService.syncError != null && orderService.orders.isEmpty) {
            return _OrdersStateMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Live orders unavailable',
              subtitle: orderService.syncError!,
            );
          }
          if (orderService.isSyncing && orderService.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (orderService.orders.isEmpty) {
            return const _OrdersStateMessage(
              icon: Icons.receipt_long,
              title: 'No orders yet',
              subtitle: 'Your orders will appear here once you place a live order.',
            );
          }
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  labelColor: AppTheme.primaryRed,
                  unselectedLabelColor: AppTheme.textLight,
                  indicatorColor: AppTheme.primaryRed,
                  tabs: [
                    Tab(text: 'Active'),
                    Tab(text: 'Past Orders'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildOrderList(
                        context,
                        orderService.activeOrders,
                        'No active orders',
                      ),
                      _buildOrderList(
                        context,
                        orderService.pastOrders,
                        'No past orders',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderList(
      BuildContext context, List orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(color: AppTheme.textLight, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return OrderCard(
          order: orders[index],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OrderTrackingScreen(orderId: orders[index].id),
            ),
          ),
        );
      },
    );
  }
}

class _OrdersStateMessage extends StatelessWidget {
  const _OrdersStateMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppTheme.textLight),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, color: AppTheme.textMedium),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textLight, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
