import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/order_card.dart';

class StoreOrdersScreen extends StatelessWidget {
  const StoreOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store Orders')),
      body: Consumer<OrderService>(
        builder: (context, orderService, _) {
          if (orderService.storeOrders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: AppTheme.textLight),
                  SizedBox(height: 16),
                  Text('No orders yet', style: TextStyle(fontSize: 18, color: AppTheme.textMedium)),
                ],
              ),
            );
          }

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  labelColor: AppTheme.primaryRed,
                  unselectedLabelColor: AppTheme.textLight,
                  indicatorColor: AppTheme.primaryRed,
                  tabs: [
                    Tab(text: 'New'),
                    Tab(text: 'In Progress'),
                    Tab(text: 'Completed'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildOrderList(
                        context,
                        orderService,
                        orderService.orders
                            .where((o) =>
                                o.status == OrderStatus.placed ||
                                o.status == OrderStatus.confirmed)
                            .toList(),
                        'No new orders',
                      ),
                      _buildOrderList(
                        context,
                        orderService,
                        orderService.orders
                            .where((o) =>
                                o.status == OrderStatus.preparing ||
                                o.status == OrderStatus.readyForPickup ||
                                o.status == OrderStatus.outForDelivery)
                            .toList(),
                        'No orders in progress',
                      ),
                      _buildOrderList(
                        context,
                        orderService,
                        orderService.orders
                            .where((o) => o.status == OrderStatus.delivered)
                            .toList(),
                        'No completed orders',
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

  Widget _buildOrderList(BuildContext context, OrderService orderService,
      List<Order> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: TextStyle(color: AppTheme.textLight, fontSize: 16)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(
          order: order,
          showActions: true,
          onUpdateStatus: () => _showStatusUpdateDialog(context, orderService, order),
        );
      },
    );
  }

  void _showStatusUpdateDialog(
      BuildContext context, OrderService orderService, Order order) {
    final nextStatuses = _getNextStatuses(order.status);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Order Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...nextStatuses.map((status) => ListTile(
                  leading: Icon(_statusIcon(status), color: AppTheme.primaryRed),
                  title: Text(_statusLabel(status)),
                  onTap: () {
                    orderService.updateOrderStatus(order.id, status);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order updated to ${_statusLabel(status)}'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  List<OrderStatus> _getNextStatuses(OrderStatus current) {
    switch (current) {
      case OrderStatus.placed:
        return [OrderStatus.confirmed, OrderStatus.cancelled];
      case OrderStatus.confirmed:
        return [OrderStatus.preparing, OrderStatus.cancelled];
      case OrderStatus.preparing:
        return [OrderStatus.readyForPickup];
      case OrderStatus.readyForPickup:
        return [OrderStatus.outForDelivery];
      case OrderStatus.outForDelivery:
        return [OrderStatus.delivered];
      default:
        return [];
    }
  }

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
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
      default:
        return Icons.info;
    }
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return 'Confirm Order';
      case OrderStatus.preparing:
        return 'Start Preparing';
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Mark Delivered';
      case OrderStatus.cancelled:
        return 'Cancel Order';
      default:
        return status.name;
    }
  }
}
