import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/mock_data.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import 'store_operations_tools_screen.dart';

class StoreDashboardScreen extends StatelessWidget {
  const StoreDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final storeOwner = auth.currentUser;
    final store = MockData.stores.firstWhere(
      (candidate) => candidate.ownerId == storeOwner?.id,
      orElse: () => MockData.stores.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F2),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store.name, style: const TextStyle(fontSize: 18)),
            Text(
              store.isOpen ? 'Open now' : 'Closed',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
      body: Consumer<OrderService>(
        builder: (context, orderService, _) {
          final earnings = orderService.earningsFor(
            UserRole.storeOwner,
            userId: store.ownerId,
          );
          final activeOrders = orderService.allOrders
              .where((order) =>
                  order.storeId == store.id &&
                  order.status != OrderStatus.delivered &&
                  order.status != OrderStatus.cancelled)
              .toList();
          final admin = orderService.adminSnapshot;
          final radius = orderService.radiusForStore(store.id);
          final averageOrderValue =
              orderService.averageOrderValueForStore(store.id);
          final activeReservations =
              orderService.activeReservationCountForStore(store.id);
          final outForDelivery =
              orderService.outForDeliveryCountForStore(store.id);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Live orders',
                      '${activeOrders.length}',
                      Icons.receipt_long_outlined,
                      const Color(0xFFBE342A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Held payout',
                      'Rs ${earnings.held.toInt()}',
                      Icons.lock_clock_outlined,
                      const Color(0xFFD58A09),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Released',
                      'Rs ${earnings.released.toInt()}',
                      Icons.payments_outlined,
                      const Color(0xFF1D8C3A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Platform share',
                      'Rs ${orderService.platformReleasedBalance.toInt()}',
                      Icons.account_balance_outlined,
                      const Color(0xFF255E96),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service radius',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Customers inside this coverage radius can place orders with this store. The default is 5 km.',
                      style: TextStyle(
                        color: AppTheme.textMedium,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${radius.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${admin['totalOrders']} platform orders tracked',
                          style: const TextStyle(color: AppTheme.textMedium),
                        ),
                      ],
                    ),
                    Slider(
                      min: 1,
                      max: 12,
                      divisions: 22,
                      value: radius,
                      onChanged: (value) =>
                          orderService.updateStoreRadius(store.id, value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Avg basket',
                      'Rs ${averageOrderValue.toInt()}',
                      Icons.analytics_outlined,
                      const Color(0xFF255E96),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Reserved stock',
                      '$activeReservations',
                      Icons.inventory_2_outlined,
                      const Color(0xFF7A4AC7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Operational analytics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$outForDelivery orders are already on the road and $activeReservations inventory reservations are currently locked for confirmed demand.',
                      style: const TextStyle(
                        color: AppTheme.textMedium,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: activeOrders.isEmpty
                          ? 0
                          : outForDelivery / activeOrders.length,
                      minHeight: 8,
                      color: const Color(0xFF1D8C3A),
                      backgroundColor: const Color(0xFFE9EDF2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StoreAnalyticsDetailScreen(),
                  ),
                ),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFFEAF1F7),
                        child: Icon(Icons.analytics_outlined, color: AppTheme.info),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Open full analytics',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Review payout state, reservation flow, and recent store order movement in one place.',
                              style: TextStyle(color: AppTheme.textMedium, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Active orders',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (activeOrders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(34),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'No active orders right now.',
                    style: TextStyle(color: AppTheme.textMedium),
                  ),
                )
              else
                ...activeOrders.map(
                  (order) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
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
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
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
                          '${order.itemCount} items • Rs ${order.grandTotal.toInt()}',
                          style: const TextStyle(
                            color: AppTheme.textMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.deliveryAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textMedium,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textMedium)),
        ],
      ),
    );
  }
}
