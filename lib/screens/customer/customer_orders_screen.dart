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
          if (orderService.orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: AppTheme.textLight),
                  SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: TextStyle(fontSize: 18, color: AppTheme.textMedium),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your orders will appear here',
                    style: TextStyle(color: AppTheme.textLight),
                  ),
                ],
              ),
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
