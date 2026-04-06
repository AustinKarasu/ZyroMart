import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/admin_auth_service.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import 'admin_operations_screens.dart';
import 'admin_preferences_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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
                              adminAuth.displayEmail,
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
                    _LiveSignalsPanel(snapshot: snapshot),
                    const SizedBox(height: 24),
                    _StatusBreakdownPanel(snapshot: snapshot),
                    const SizedBox(height: 24),
                    _OperationsPanel(snapshot: snapshot),
                    const SizedBox(height: 24),
                    _AdminRunbookPanel(snapshot: snapshot),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionLaunchCard(
                            title: 'Metrics history',
                            subtitle: 'Inspect recent daily platform totals and payout drift.',
                            icon: Icons.query_stats_rounded,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminMetricsHistoryScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActionLaunchCard(
                            title: 'Operations feed',
                            subtitle: 'Open the full event stream for recent order movement.',
                            icon: Icons.feed_outlined,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminOperationsLogScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _ActionLaunchCard(
                      title: 'Admin preferences',
                      subtitle: 'Configure how this control-room account prioritizes signals, metrics windows, and cancellation emphasis.',
                      icon: Icons.tune_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminPreferencesScreen(),
                        ),
                      ),
                    ),
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
                            'This target is isolated from customer, store owner, and delivery flows. Build it with flutter build apk --flavor admin -t lib/admin_main.dart for a dedicated admin application package.',
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

class _ActionLaunchCard extends StatelessWidget {
  const _ActionLaunchCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryRed),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: AppTheme.textMedium, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _AdminRunbookPanel extends StatelessWidget {
  const _AdminRunbookPanel({required this.snapshot});

  final AdminDashboardSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final counts = snapshot?.orderStatusCounts ?? const <String, int>{};
    final delayed = (counts['preparing'] ?? 0) + (counts['ready_for_pickup'] ?? 0);
    final onRoad = counts['out_for_delivery'] ?? 0;
    final cancelled = counts['cancelled'] ?? 0;
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
            'Operator focus',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          _focusRow(
            color: const Color(0xFFD58A09),
            title: 'Store-side delays',
            subtitle: '$delayed orders are still being prepared or waiting for pickup.',
          ),
          const SizedBox(height: 10),
          _focusRow(
            color: const Color(0xFF255E96),
            title: 'On-road handoffs',
            subtitle: '$onRoad orders are with riders and should be watched for OTP completion.',
          ),
          const SizedBox(height: 10),
          _focusRow(
            color: const Color(0xFFBE342A),
            title: 'Cancellation watch',
            subtitle: '$cancelled orders cancelled today. Review trends if this keeps climbing.',
          ),
        ],
      ),
    );
  }

  Widget _focusRow({
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textMedium,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBreakdownPanel extends StatelessWidget {
  const _StatusBreakdownPanel({required this.snapshot});

  final AdminDashboardSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final counts = snapshot?.orderStatusCounts ?? const <String, int>{};
    final labels = const {
      'placed': 'Placed',
      'confirmed': 'Confirmed',
      'preparing': 'Preparing',
      'ready_for_pickup': 'Ready for pickup',
      'out_for_delivery': 'Out for delivery',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
    };
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
            'Order status breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          ...labels.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: AppTheme.textMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${counts[entry.key] ?? 0}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101927),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveSignalsPanel extends StatelessWidget {
  const _LiveSignalsPanel({required this.snapshot});

  final AdminDashboardSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final signals = snapshot?.liveSignals ?? const <String, dynamic>{};
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
            'Live Signals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _signalChip('Pending', '${signals['pending_orders'] ?? 0}'),
              _signalChip('Proof Ready', '${signals['proof_of_delivery_ready'] ?? 0}'),
              _signalChip('Active Customers', '${signals['active_customers'] ?? 0}'),
              _signalChip('Riders Online', '${signals['active_delivery_partners'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signalChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OperationsPanel extends StatelessWidget {
  const _OperationsPanel({required this.snapshot});

  final AdminDashboardSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final events = snapshot?.recentOperationalEvents ?? const [];
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
            'Operational Feed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          if (events.isEmpty)
            const Text(
              'Recent order and platform events will appear here once traffic starts moving through the live backend.',
              style: TextStyle(color: AppTheme.textMedium, height: 1.45),
            )
          else
            ...events.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: event['color'] as Color? ?? AppTheme.primaryRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (event['title'] ?? '').toString(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (event['subtitle'] ?? '').toString(),
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
            ),
        ],
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
