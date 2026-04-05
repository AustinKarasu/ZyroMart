import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/order_service.dart';
import '../../services/mock_data.dart';
import '../../theme/app_theme.dart';

class StoreDashboardScreen extends StatelessWidget {
  const StoreDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderService = context.watch<OrderService>();
    final store = MockData.stores[0];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ZyroMart Central', style: TextStyle(fontSize: 18)),
            Text(
              store.isOpen ? 'Open Now' : 'Closed',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Today\'s Orders',
                    '${orderService.orders.length}',
                    Icons.receipt_long,
                    AppTheme.primaryRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Revenue',
                    'â‚¹${store.totalRevenue.toInt()}',
                    Icons.currency_rupee,
                    AppTheme.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Orders',
                    '${store.totalOrders}',
                    Icons.shopping_bag,
                    AppTheme.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Rating',
                    '${store.rating}',
                    Icons.star,
                    AppTheme.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Active orders
            const Text(
              'Active Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (orderService.activeOrders.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('No active orders', style: TextStyle(color: AppTheme.textLight)),
                ),
              )
            else
              ...orderService.activeOrders.map((order) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: AppTheme.cardShadow, blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('#${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.statusLabel,
                                style: const TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${order.itemCount} items â€¢ â‚¹${order.grandTotal.toInt()}', style: TextStyle(color: AppTheme.textMedium)),
                        const SizedBox(height: 4),
                        Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(order.customerPhone, style: const TextStyle(color: AppTheme.textMedium, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(order.deliveryAddress, style: TextStyle(color: AppTheme.textLight, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  )),
            const SizedBox(height: 24),

            // Products overview
            const Text('Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildProductStat('Total', '${MockData.products.length}', AppTheme.textDark),
                  _buildProductStat('In Stock', '${MockData.products.where((p) => p.inStock).length}', AppTheme.success),
                  _buildProductStat('Out of Stock', '${MockData.products.where((p) => !p.inStock).length}', AppTheme.primaryRed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppTheme.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: AppTheme.textMedium, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildProductStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: AppTheme.textMedium, fontSize: 13)),
      ],
    );
  }
}

