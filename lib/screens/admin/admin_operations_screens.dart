import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminMetricsHistoryScreen extends StatelessWidget {
  const AdminMetricsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final snapshot = context.watch<AdminService>().snapshot;
    final history = snapshot?.metricsHistory ?? const [];
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: 'INR ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Metrics history')),
      body: history.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Daily platform metric rows will appear here once they are written into Supabase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMedium, height: 1.6),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final row = history[index];
                final date = DateTime.tryParse((row['metric_date'] ?? '').toString());
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          date == null ? 'Metric row ${index + 1}' : DateFormat('dd MMM yyyy').format(date),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        _row('GMV', currency.format(((row['gross_merchandise_value'] ?? 0) as num).toDouble())),
                        _row('Platform commission', currency.format(((row['platform_commission_earned'] ?? 0) as num).toDouble())),
                        _row('Delivery payout due', currency.format(((row['delivery_payout_due'] ?? 0) as num).toDouble())),
                        _row('Store payout due', currency.format(((row['store_payout_due'] ?? 0) as num).toDouble())),
                        _row('Completed orders', '${row['completed_orders'] ?? 0}'),
                        _row('Cancelled orders', '${row['cancelled_orders'] ?? 0}'),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemCount: history.length,
            ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textMedium))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class AdminOperationsLogScreen extends StatelessWidget {
  const AdminOperationsLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final snapshot = context.watch<AdminService>().snapshot;
    final events = snapshot?.recentOperationalEvents ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Operational feed')),
      body: events.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Recent platform events will appear here as order traffic moves through the backend.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMedium, height: 1.6),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final event = events[index];
                final color = event['color'] as Color? ?? AppTheme.info;
                final timestamp =
                    DateTime.tryParse((event['timestamp'] ?? '').toString());
                final source = (event['source'] ?? 'ops').toString();
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Icon(Icons.fiber_manual_record, color: color, size: 16),
                    ),
                    title: Text((event['title'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((event['subtitle'] ?? '').toString()),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _OpsChip(
                              label: source.toUpperCase(),
                              color: color,
                            ),
                            if (timestamp != null)
                              _OpsChip(
                                label: DateFormat('dd MMM, hh:mm a')
                                    .format(timestamp),
                                color: const Color(0xFF4B5B6A),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemCount: events.length,
            ),
    );
  }
}

class _OpsChip extends StatelessWidget {
  const _OpsChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
