import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';

class StoreOrderDetailScreen extends StatelessWidget {
  const StoreOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order $orderId')),
      body: Consumer<OrderService>(
        builder: (context, orderService, _) {
          final order = orderService.getOrder(orderId);
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }
          final events = orderService.statusEventsForOrder(order.id);
          final reservations =
              orderService.inventoryReservationsForOrder(order.id);
          final proof = orderService.proofOfDeliveryForOrder(order.id);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#${order.id}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          order.statusLabel,
                          style: const TextStyle(
                            color: AppTheme.primaryRed,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${order.customerName} • ${order.customerPhone}',
                      style: const TextStyle(
                        color: AppTheme.textMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.deliveryAddress,
                      style: const TextStyle(
                        color: AppTheme.textMedium,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _section(
                title: 'Items and reservations',
                child: Column(
                  children: [
                    ...order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.product.name} x${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text('Rs ${item.totalPrice.toInt()}'),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                    if (reservations.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No live reservations found yet for this order.',
                          style: TextStyle(color: AppTheme.textMedium),
                        ),
                      )
                    else
                      ...reservations.map(
                        (reservation) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 18,
                                color: AppTheme.info,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${reservation['reserved_quantity'] ?? 0} reserved • ${(reservation['reservation_status'] ?? '').toString()}',
                                  style: const TextStyle(
                                    color: AppTheme.textMedium,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _section(
                title: 'Timeline',
                child: events.isEmpty
                    ? const Text(
                        'Status changes will appear here as the order progresses.',
                        style: TextStyle(color: AppTheme.textMedium),
                      )
                    : Column(
                        children: events
                            .map(
                              (event) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryRed,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (event['next_status'] ?? '')
                                                .toString()
                                                .replaceAll('_', ' '),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            (event['notes'] ?? '').toString(),
                                            style: const TextStyle(
                                              color: AppTheme.textMedium,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 14),
              _section(
                title: 'Proof of delivery',
                child: Text(
                  proof == null
                      ? 'Proof will be available after the rider completes OTP verification.'
                      : 'Delivered to ${(proof['handed_to_name'] ?? order.customerName).toString()} • ${(proof['notes'] ?? 'No delivery notes').toString()}',
                  style: const TextStyle(
                    color: AppTheme.textMedium,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _ActionPanel(order: order),
            ],
          );
        },
      ),
    );
  }

  Widget _section({String? title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final orderService = context.read<OrderService>();
    final nextStatuses = _getNextStatuses(order.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Store actions',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: nextStatuses
                .map(
                  (status) => status == OrderStatus.cancelled
                      ? OutlinedButton(
                          onPressed: () => _apply(context, orderService, status),
                          child: Text(_label(status)),
                        )
                      : ElevatedButton(
                          onPressed: () => _apply(context, orderService, status),
                          child: Text(_label(status)),
                        ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  void _apply(
    BuildContext context,
    OrderService orderService,
    OrderStatus status,
  ) {
    final success = orderService.updateOrderStatus(order.id, status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Order updated to ${_label(status)}'
              : 'Could not move order to ${_label(status)}',
        ),
        backgroundColor: success ? AppTheme.success : AppTheme.primaryRed,
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
        return const [];
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return const [];
    }
  }

  String _label(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return 'Confirm';
      case OrderStatus.preparing:
        return 'Start preparing';
      case OrderStatus.readyForPickup:
        return 'Ready for pickup';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Decline order';
      case OrderStatus.placed:
        return 'Placed';
    }
  }
}
