import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/admin_auth_service.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminService>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminAuth = context.watch<AdminAuthService>();
    final admin = context.watch<AdminService>();
    final snapshot = admin.snapshot;
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'INR ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminService>().loadDashboard(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF091525), Color(0xFF163250), Color(0xFF1D507B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ZyroMart Control Room',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              adminAuth.currentUser?.email ?? 'Signed in admin',
                              style: const TextStyle(
                                color: Color(0xFFD4DEEB),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: adminAuth.signOut,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Sign Out'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.14),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroStatCard(
                          title: 'Pending Platform Share',
                          value: snapshot == null
                              ? '--'
                              : currency.format(snapshot.pendingPlatformBalance),
                          icon: Icons.account_balance_wallet_rounded,
                          tint: const Color(0xFF0CBA86),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _HeroStatCard(
                          title: 'Paid Out Platform Share',
                          value: snapshot == null
                              ? '--'
                              : currency.format(snapshot.paidPlatformBalance),
                          icon: Icons.payments_rounded,
                          tint: const Color(0xFFFFB23E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (admin.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        admin.errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (admin.isLoading && snapshot == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    const Text(
                      'Platform Snapshot',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F1824),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _InfoTile(
                          label: 'Orders',
                          value: '${snapshot?.totalOrders ?? 0}',
                          icon: Icons.receipt_long_rounded,
                        ),
                        _InfoTile(
                          label: 'Products',
                          value: '${snapshot?.totalProducts ?? 0}',
                          icon: Icons.inventory_2_rounded,
                        ),
                        _InfoTile(
                          label: 'Stores',
                          value: '${snapshot?.totalStores ?? 0}',
                          icon: Icons.storefront_rounded,
                        ),
                        _InfoTile(
                          label: 'Customers',
                          value: '${snapshot?.totalCustomers ?? 0}',
                          icon: Icons.groups_rounded,
                        ),
                        _InfoTile(
                          label: 'Delivery Partners',
                          value: '${snapshot?.totalDeliveryPartners ?? 0}',
                          icon: Icons.delivery_dining_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _MetricsPanel(snapshot: snapshot, currency: currency),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Separate Admin APK',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'This target is isolated from customer, store owner, and delivery flows. Build it with flutter build apk -t lib/admin_main.dart for a dedicated admin application package.',
                            style: TextStyle(
                              color: AppTheme.textMedium,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  const _HeroStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tint, size: 28),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFD7E2EE),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryRed),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF101927),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMedium),
          ),
        ],
      ),
    );
  }
}

class _MetricsPanel extends StatelessWidget {
  const _MetricsPanel({
    required this.snapshot,
    required this.currency,
  });

  final AdminDashboardSnapshot? snapshot;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final latest = snapshot?.latestMetrics;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Latest Daily Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (latest == null)
            const Text(
              'No rows in platform_daily_metrics yet. The admin app is ready and will populate this panel as soon as metrics are written into Supabase.',
              style: TextStyle(color: AppTheme.textMedium, height: 1.5),
            )
          else
            Column(
              children: [
                _metricRow(
                  'GMV',
                  currency.format(
                    ((latest['gross_merchandise_value'] ?? 0) as num).toDouble(),
                  ),
                ),
                _metricRow(
                  'Platform Commission',
                  currency.format(
                    ((latest['platform_commission_earned'] ?? 0) as num)
                        .toDouble(),
                  ),
                ),
                _metricRow(
                  'Delivery Payout Due',
                  currency.format(
                    ((latest['delivery_payout_due'] ?? 0) as num).toDouble(),
                  ),
                ),
                _metricRow(
                  'Store Payout Due',
                  currency.format(
                    ((latest['store_payout_due'] ?? 0) as num).toDouble(),
                  ),
                ),
                _metricRow(
                  'Completed Orders',
                  '${latest['completed_orders'] ?? 0}',
                ),
                _metricRow(
                  'Cancelled Orders',
                  '${latest['cancelled_orders'] ?? 0}',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF101927),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
