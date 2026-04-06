import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/order_service.dart';
import '../../theme/app_theme.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({
    super.key,
    this.title = 'Notifications',
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Consumer<OrderService>(
        builder: (context, orderService, _) {
          final notifications = orderService.notifications;
          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(color: AppTheme.textMedium),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                leading: CircleAvatar(
                  backgroundColor: notification.isRead
                      ? const Color(0xFFECEFF3)
                      : const Color(0xFFE5F5E9),
                  child: Icon(
                    _iconFor(notification.category),
                    color: notification.isRead
                        ? AppTheme.textMedium
                        : const Color(0xFF1D8C3A),
                  ),
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead
                        ? FontWeight.w600
                        : FontWeight.w800,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    notification.body,
                    style: const TextStyle(height: 1.35),
                  ),
                ),
                trailing: notification.isRead
                    ? null
                    : const Icon(
                        Icons.fiber_manual_record,
                        color: Color(0xFF1D8C3A),
                        size: 12,
                      ),
                onTap: () {
                  orderService.markNotificationRead(notification.id);
                },
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemCount: notifications.length,
          );
        },
      ),
    );
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'order':
        return Icons.receipt_long_rounded;
      case 'earning':
        return Icons.account_balance_wallet_outlined;
      case 'promotion':
        return Icons.local_offer_outlined;
      case 'recommendation':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }
}
