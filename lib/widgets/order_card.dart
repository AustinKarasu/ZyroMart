import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final bool showActions;
  final VoidCallback? onAccept;
  final VoidCallback? onUpdateStatus;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.showActions = false,
    this.onAccept,
    this.onUpdateStatus,
  });

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return AppTheme.info;
      case OrderStatus.confirmed:
        return Colors.indigo;
      case OrderStatus.preparing:
        return AppTheme.warning;
      case OrderStatus.readyForPickup:
        return Colors.deepPurple;
      case OrderStatus.outForDelivery:
        return AppTheme.primaryRed;
      case OrderStatus.delivered:
        return AppTheme.success;
      case OrderStatus.cancelled:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _statusColor(order.status).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(
                      color: _statusColor(order.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.itemCount} items • ₹${order.grandTotal.toInt()}',
              style: TextStyle(color: AppTheme.textMedium, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              order.deliveryAddress,
              style: TextStyle(color: AppTheme.textLight, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Progress bar
            if (order.status != OrderStatus.cancelled &&
                order.status != OrderStatus.delivered)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: order.statusProgress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _statusColor(order.status)),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.customerName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (order.deliveryPersonName != null)
                  Row(
                    children: [
                      Icon(Icons.delivery_dining,
                          size: 16, color: AppTheme.textLight),
                      const SizedBox(width: 4),
                      Text(
                        order.deliveryPersonName!,
                        style: TextStyle(
                          color: AppTheme.textMedium,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (showActions &&
                order.status != OrderStatus.delivered &&
                order.status != OrderStatus.cancelled) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onAccept != null &&
                      (order.status == OrderStatus.placed ||
                          order.status == OrderStatus.readyForPickup))
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        child: Text(
                          order.status == OrderStatus.readyForPickup
                              ? 'Pick Up'
                              : 'Accept',
                        ),
                      ),
                    ),
                  if (onUpdateStatus != null &&
                      order.status != OrderStatus.placed) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onUpdateStatus,
                        child: const Text('Update Status'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
