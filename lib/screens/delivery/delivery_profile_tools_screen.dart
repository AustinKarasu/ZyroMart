import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/user.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';

class DeliveryEarningsScreen extends StatelessWidget {
  final AppUser? user;

  const DeliveryEarningsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final orderService = context.watch<OrderService>();
    final earnings = orderService.earningsFor(
      UserRole.delivery,
      userId: user?.id,
    );
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payout overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text(
                    'Held earnings are waiting for successful order completion. Released earnings are ready for settlement.',
                    style: TextStyle(color: AppTheme.textMedium, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _AmountMetric(label: 'Held', value: currency.format(earnings.held), color: AppTheme.warning),
                      const SizedBox(width: 10),
                      _AmountMetric(label: 'Released', value: currency.format(earnings.released), color: AppTheme.success),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _AmountMetric(label: 'Lifetime', value: currency.format(earnings.lifetime), color: AppTheme.info),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_shipping_outlined, color: AppTheme.info),
              title: const Text('Completed deliveries'),
              trailing: Text(
                '${earnings.completedOrders}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryHistoryScreen extends StatelessWidget {
  final AppUser? user;

  const DeliveryHistoryScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final orderService = context.watch<OrderService>();
    final deliveredOrders = orderService.pastOrders
        .where(
          (order) =>
              order.deliveryPersonId == user?.id &&
              order.status == OrderStatus.delivered,
        )
        .toList()
      ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery history')),
      body: deliveredOrders.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Completed deliveries will appear here once you finish active orders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMedium, height: 1.6),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final order = deliveredOrders[index];
                final proof = orderService.proofOfDeliveryForOrder(order.id);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                order.storeName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Delivered',
                                style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Order ${order.id} • ${DateFormat('dd MMM, hh:mm a').format(order.placedAt)}'),
                        const SizedBox(height: 6),
                        Text('Customer: ${order.customerName}'),
                        Text('Address: ${order.deliveryAddress}', style: const TextStyle(height: 1.4)),
                        if (proof != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Proof: handed to ${(proof['handed_to_name'] ?? order.customerName).toString()}',
                            style: const TextStyle(color: AppTheme.textMedium),
                          ),
                          if ((proof['notes'] ?? '').toString().trim().isNotEmpty)
                            Text(
                              'Notes: ${(proof['notes'] ?? '').toString()}',
                              style: const TextStyle(color: AppTheme.textMedium),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, separatorIndex) => const SizedBox(height: 12),
              itemCount: deliveredOrders.length,
            ),
    );
  }
}

class _AmountMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AmountMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
