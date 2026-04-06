import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/mock_data.dart';
import '../../services/order_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class StoreAnalyticsDetailScreen extends StatelessWidget {
  const StoreAnalyticsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final orderService = context.watch<OrderService>();
    final owner = auth.currentUser;
    final fallbackStore = MockData.stores.firstWhere(
      (candidate) => candidate.ownerId == owner?.id,
      orElse: () => MockData.stores.first,
    );

    return FutureBuilder<Map<String, dynamic>?>(
      future: owner == null || !SupabaseService.isInitialized
          ? Future.value(null)
          : SupabaseService.getStoreByOwner(owner.id),
      builder: (context, storeSnapshot) {
        final storeRow = storeSnapshot.data;
        final storeId = (storeRow?['id'] ?? fallbackStore.id).toString();
        final ownerId = owner?.id ?? fallbackStore.ownerId;
        final earnings =
            orderService.earningsFor(UserRole.storeOwner, userId: ownerId);
        final storeOrders = orderService.allOrders
            .where((order) => order.storeId == storeId)
            .toList()
          ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
        final activeOrders = storeOrders
            .where(
              (order) =>
                  order.status != OrderStatus.delivered &&
                  order.status != OrderStatus.cancelled,
            )
            .toList();
        final deliveredOrders = storeOrders
            .where((order) => order.status == OrderStatus.delivered)
            .toList();
        final cancelledOrders = storeOrders
            .where((order) => order.status == OrderStatus.cancelled)
            .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Store analytics')),
          body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AnalyticsCard(
            title: 'Revenue and payout state',
            subtitle: 'Held revenue is waiting for completed delivery confirmation. Released revenue is ready after successful handoff.',
            child: Row(
              children: [
                Expanded(child: _MetricPill(label: 'Held', value: 'Rs ${earnings.held.toInt()}', color: AppTheme.warning)),
                const SizedBox(width: 10),
                Expanded(child: _MetricPill(label: 'Released', value: 'Rs ${earnings.released.toInt()}', color: AppTheme.success)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AnalyticsCard(
            title: 'Operations summary',
            subtitle: 'These figures come from the shared order lifecycle and inventory reservation logic.',
            child: Column(
              children: [
                _summaryRow('Active orders', '${activeOrders.length}'),
                _summaryRow('Delivered orders', '${deliveredOrders.length}'),
                _summaryRow('Cancelled orders', '${cancelledOrders.length}'),
                _summaryRow('Avg basket value', 'Rs ${orderService.averageOrderValueForStore(storeId).toInt()}'),
                _summaryRow('Reserved stock buckets', '${orderService.activeReservationCountForStore(storeId)}'),
                _summaryRow('Live route pings', '${orderService.routePingCountForStore(storeId)}'),
                _summaryRow('Service radius', '${orderService.radiusForStore(storeId).toStringAsFixed(1)} km'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AnalyticsCard(
            title: 'Recent order stream',
            subtitle: 'Use this to watch how the store is moving through placed, preparation, handoff, and delivered states.',
            child: storeOrders.isEmpty
                ? const Text(
                    'No store orders are available yet.',
                    style: TextStyle(color: AppTheme.textMedium, height: 1.5),
                  )
                : Column(
                    children: storeOrders.take(10).map((order) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(order.status).withValues(alpha: 0.12),
                          child: Icon(Icons.receipt_long, color: _statusColor(order.status)),
                        ),
                        title: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${order.statusLabel} • ${order.itemCount} items'),
                        trailing: Text('Rs ${order.grandTotal.toInt()}'),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _AnalyticsCard(
            title: 'Inventory reservations',
            subtitle: 'Reservation locks are created when orders are placed and released or consumed as fulfillment progresses.',
            child: activeOrders.isEmpty
                ? const Text(
                    'No active reservations at the moment.',
                    style: TextStyle(color: AppTheme.textMedium, height: 1.5),
                  )
                : Column(
                    children: activeOrders.take(6).map((order) {
                      final reservations = orderService.inventoryReservationsForOrder(order.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order ${order.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              reservations.isEmpty
                                  ? 'No reservation rows recorded yet'
                                  : reservations
                                      .map((reservation) => '${reservation['reserved_quantity']}x ${(reservation['product_id'] ?? '').toString()} • ${(reservation['reservation_status'] ?? '').toString()}')
                                      .join('\n'),
                              style: const TextStyle(color: AppTheme.textMedium, height: 1.4),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textMedium))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return AppTheme.success;
      case OrderStatus.cancelled:
        return AppTheme.primaryRed;
      case OrderStatus.outForDelivery:
        return AppTheme.info;
      case OrderStatus.preparing:
      case OrderStatus.readyForPickup:
        return AppTheme.warning;
      case OrderStatus.placed:
      case OrderStatus.confirmed:
        return const Color(0xFF4B5B6A);
    }
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _AnalyticsCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: AppTheme.textMedium, height: 1.45)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }
}
