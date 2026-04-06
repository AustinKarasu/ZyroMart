import 'package:flutter/material.dart';

import '../models/order.dart';
import 'mock_data.dart';
import 'supabase_service.dart';

class AdminDashboardSnapshot {
  const AdminDashboardSnapshot({
    required this.totalOrders,
    required this.totalProducts,
    required this.totalStores,
    required this.totalCustomers,
    required this.totalDeliveryPartners,
    required this.pendingPlatformBalance,
    required this.paidPlatformBalance,
    required this.latestMetrics,
    required this.metricsHistory,
    required this.recentOperationalEvents,
    required this.liveSignals,
    required this.orderStatusCounts,
  });

  final int totalOrders;
  final int totalProducts;
  final int totalStores;
  final int totalCustomers;
  final int totalDeliveryPartners;
  final double pendingPlatformBalance;
  final double paidPlatformBalance;
  final Map<String, dynamic>? latestMetrics;
  final List<Map<String, dynamic>> metricsHistory;
  final List<Map<String, dynamic>> recentOperationalEvents;
  final Map<String, dynamic> liveSignals;
  final Map<String, int> orderStatusCounts;
}

class AdminService extends ChangeNotifier {
  AdminDashboardSnapshot? _snapshot;
  bool _isLoading = false;
  String? _errorMessage;

  AdminDashboardSnapshot? get snapshot => _snapshot;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard() async {
    if (!SupabaseService.isInitialized) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        SupabaseService.getOrders(),
        SupabaseService.getProducts(),
        SupabaseService.getStores(),
        SupabaseService.getProfiles(),
        SupabaseService.getEarningsLedger(beneficiaryRole: 'platform'),
        SupabaseService.getPlatformDailyMetrics(limit: 7),
        SupabaseService.getAppUsageEvents(limit: 120),
        SupabaseService.getCrashReports(limit: 40),
      ]);

      final orders = List<Map<String, dynamic>>.from(results[0] as List);
      final products = List<Map<String, dynamic>>.from(results[1] as List);
      final stores = List<Map<String, dynamic>>.from(results[2] as List);
      final profiles = List<Map<String, dynamic>>.from(results[3] as List);
      final platformLedger = List<Map<String, dynamic>>.from(results[4] as List);
      final metrics = List<Map<String, dynamic>>.from(results[5] as List);
      final usageEvents = List<Map<String, dynamic>>.from(results[6] as List);
      final crashReports = List<Map<String, dynamic>>.from(results[7] as List);
      final latest = metrics.isEmpty ? null : metrics.first;
      final recentOrders = orders.take(6).toList();
      final detailResults = await Future.wait(
        recentOrders.map(_loadOperationalDetail),
      );

      double pending = 0;
      double paid = 0;
      for (final entry in platformLedger) {
        final amount = ((entry['net_amount'] ?? 0) as num).toDouble();
        if (entry['settlement_state'] == 'paid_out') {
          paid += amount;
        } else {
          pending += amount;
        }
      }

      _snapshot = AdminDashboardSnapshot(
        totalOrders: orders.length,
        totalProducts: products.length,
        totalStores: stores.length,
        totalCustomers:
            profiles.where((row) => row['role'] == 'customer').length,
        totalDeliveryPartners:
            profiles.where((row) => row['role'] == 'delivery').length,
        pendingPlatformBalance: pending,
        paidPlatformBalance: paid,
        latestMetrics: latest,
        metricsHistory: metrics,
        recentOperationalEvents: _buildOperationalEvents(
          recentOrders,
          detailResults,
          usageEvents,
          crashReports,
        ),
        liveSignals: {
          'pending_orders': orders
              .where(
                (row) =>
                    row['status'] != 'delivered' &&
                    row['status'] != 'cancelled',
              )
              .length,
          'proof_of_delivery_ready': detailResults
              .where((detail) => detail['proof'] != null)
              .length,
          'active_route_pings': detailResults.fold<int>(
            0,
            (sum, detail) =>
                sum +
                (detail['route_updates'] as List<Map<String, dynamic>>).length,
          ),
          'active_customers': latest?['active_customers'] ?? 0,
          'active_delivery_partners':
              latest?['active_delivery_partners'] ?? 0,
          'top_feature': _topFeature(usageEvents),
          'crashes_24h': _recentCrashCount(crashReports),
        },
        orderStatusCounts: _buildStatusCounts(orders),
      );
    } catch (error) {
      _errorMessage = 'Could not load admin dashboard. ${error.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadLocalDashboard() {
    _errorMessage =
        'Running in local owner mode. Live Supabase admin access is not available for this session.';
    final completedOrders = MockData.sampleOrders
        .where((o) => o.status == OrderStatus.delivered)
        .length;
    final pendingOrders = MockData.sampleOrders
        .where(
          (o) =>
              o.status != OrderStatus.delivered &&
              o.status != OrderStatus.cancelled,
        )
        .length;
    final grossValue = MockData.sampleOrders.fold<double>(
      0,
      (sum, order) => sum + order.grandTotal,
    );
    _snapshot = AdminDashboardSnapshot(
      totalOrders: MockData.sampleOrders.length,
      totalProducts: MockData.products.length,
      totalStores: MockData.stores.length,
      totalCustomers: 1,
      totalDeliveryPartners: MockData.deliveryPersons.length,
      pendingPlatformBalance: grossValue * 0.05,
      paidPlatformBalance: 0,
      latestMetrics: {
        'gross_merchandise_value': grossValue,
        'platform_commission_earned': grossValue * 0.05,
        'delivery_payout_due': MockData.sampleOrders.fold<double>(
          0,
          (sum, order) => sum + order.deliveryFee + order.deliveryTip,
        ),
        'store_payout_due': grossValue * 0.95,
        'completed_orders': completedOrders,
        'cancelled_orders': MockData.sampleOrders
            .where((o) => o.status == OrderStatus.cancelled)
            .length,
        'pending_orders': pendingOrders,
      },
      metricsHistory: [
        {
          'metric_date': DateTime.now().toIso8601String(),
          'gross_merchandise_value': grossValue,
          'platform_commission_earned': grossValue * 0.05,
          'delivery_payout_due': MockData.sampleOrders.fold<double>(
            0,
            (sum, order) => sum + order.deliveryFee + order.deliveryTip,
          ),
          'store_payout_due': grossValue * 0.95,
          'completed_orders': completedOrders,
          'cancelled_orders': MockData.sampleOrders
              .where((o) => o.status == OrderStatus.cancelled)
              .length,
        },
      ],
      recentOperationalEvents: MockData.sampleOrders.take(8).map((order) {
        final status = order.statusLabel;
        return {
          'title': 'Order ${order.id}',
          'subtitle': '$status • ${order.customerName}',
          'color': _eventColorForStatus(order.status.name),
          'timestamp': order.placedAt.toIso8601String(),
          'source': 'order',
        };
      }).toList(),
      liveSignals: {
        'pending_orders': pendingOrders,
        'proof_of_delivery_ready': completedOrders,
        'active_route_pings': 0,
        'active_customers': 1,
        'active_delivery_partners':
            MockData.deliveryPersons.where((item) => item.isOnline).length,
      },
      orderStatusCounts: {
        'placed': MockData.sampleOrders
            .where((o) => o.status == OrderStatus.placed)
            .length,
        'confirmed': MockData.sampleOrders
            .where((o) => o.status == OrderStatus.confirmed)
            .length,
        'preparing': MockData.sampleOrders
            .where((o) => o.status == OrderStatus.preparing)
            .length,
        'ready_for_pickup': MockData.sampleOrders
            .where((o) => o.status == OrderStatus.readyForPickup)
            .length,
        'out_for_delivery': MockData.sampleOrders
            .where((o) => o.status == OrderStatus.outForDelivery)
            .length,
        'delivered': completedOrders,
        'cancelled': MockData.sampleOrders
            .where((o) => o.status == OrderStatus.cancelled)
            .length,
      },
    );
    notifyListeners();
  }

  Future<Map<String, dynamic>> _loadOperationalDetail(
    Map<String, dynamic> row,
  ) async {
    final orderId = (row['id'] ?? '').toString();
    if (orderId.isEmpty) {
      return {
        'status_events': <Map<String, dynamic>>[],
        'route_updates': <Map<String, dynamic>>[],
        'proof': null,
      };
    }
    final details = await Future.wait([
      SupabaseService.getOrderStatusEvents(orderId)
          .catchError((_) => <Map<String, dynamic>>[]),
      SupabaseService.getDeliveryRouteUpdates(orderId)
          .catchError((_) => <Map<String, dynamic>>[]),
      SupabaseService.getProofOfDelivery(orderId).catchError((_) => null),
    ]);
    return {
      'status_events': List<Map<String, dynamic>>.from(details[0] as List),
      'route_updates': List<Map<String, dynamic>>.from(details[1] as List),
      'proof': details[2] is Map<String, dynamic>
          ? Map<String, dynamic>.from(details[2] as Map)
          : null,
    };
  }

  List<Map<String, dynamic>> _buildOperationalEvents(
    List<Map<String, dynamic>> orders,
    List<Map<String, dynamic>> detailResults,
    List<Map<String, dynamic>> usageEvents,
    List<Map<String, dynamic>> crashReports,
  ) {
    final events = <Map<String, dynamic>>[];
    for (var index = 0; index < orders.length && index < detailResults.length; index++) {
      final row = orders[index];
      final detail = detailResults[index];
      final orderLabel = (row['order_number'] ?? row['id'] ?? '').toString();
      final customerName = (row['customer_name'] ?? 'Customer').toString();
      final status = (row['status'] ?? 'placed').toString();
      events.add({
        'title': 'Order $orderLabel',
        'subtitle': '${status.replaceAll('_', ' ')} • $customerName',
        'color': _eventColorForStatus(status),
        'timestamp': (row['created_at'] ?? '').toString(),
        'source': 'order',
      });
      for (final event in detail['status_events'] as List<Map<String, dynamic>>) {
        final nextStatus = (event['next_status'] ?? status).toString();
        events.add({
          'title': 'Status update for $orderLabel',
          'subtitle':
              '${nextStatus.replaceAll('_', ' ')} • ${(event['notes'] ?? 'Status changed').toString()}',
          'color': _eventColorForStatus(nextStatus),
          'timestamp': (event['created_at'] ?? '').toString(),
          'source': 'status',
        });
      }
      for (final update in (detail['route_updates'] as List<Map<String, dynamic>>)
          .take(2)) {
        final eta = (update['eta_minutes'] as num?)?.round();
        events.add({
          'title': 'Route ping for $orderLabel',
          'subtitle': eta == null
              ? 'Live GPS updated for $customerName'
              : 'ETA $eta min • live GPS refreshed',
          'color': const Color(0xFF255E96),
          'timestamp': (update['captured_at'] ?? '').toString(),
          'source': 'route',
        });
      }
      final proof = detail['proof'];
      if (proof is Map<String, dynamic>) {
        events.add({
          'title': 'Proof captured for $orderLabel',
          'subtitle':
              'Delivered to ${(proof['handed_to_name'] ?? customerName).toString()}',
          'color': const Color(0xFF176B3A),
          'timestamp': (proof['delivered_at'] ?? '').toString(),
          'source': 'proof',
        });
      }
    }
    for (final event in usageEvents.take(4)) {
      events.add({
        'title': 'Feature usage',
        'subtitle':
            '${(event['event_name'] ?? 'unknown').toString().replaceAll('_', ' ')} • ${(event['app_variant'] ?? 'storefront').toString()}',
        'color': const Color(0xFF7A4AC7),
        'timestamp': (event['created_at'] ?? '').toString(),
        'source': 'feature',
      });
    }
    for (final crash in crashReports.take(4)) {
      events.add({
        'title': 'Crash report',
        'subtitle':
            '${(crash['app_variant'] ?? 'storefront').toString()} • ${(crash['message'] ?? 'Unhandled exception').toString()}',
        'color': const Color(0xFFBE342A),
        'timestamp': (crash['created_at'] ?? '').toString(),
        'source': 'crash',
      });
    }
    events.sort(
      (a, b) => (b['timestamp'] ?? '').toString().compareTo(
            (a['timestamp'] ?? '').toString(),
          ),
    );
    return events.take(12).toList();
  }

  static Color _eventColorForStatus(String status) {
    switch (status) {
      case 'delivered':
        return const Color(0xFF176B3A);
      case 'cancelled':
        return const Color(0xFFBE342A);
      case 'out_for_delivery':
        return const Color(0xFF255E96);
      case 'preparing':
      case 'ready_for_pickup':
        return const Color(0xFFD58A09);
      default:
        return const Color(0xFF4B5B6A);
    }
  }

  Map<String, int> _buildStatusCounts(List<Map<String, dynamic>> orders) {
    final counts = <String, int>{
      'placed': 0,
      'confirmed': 0,
      'preparing': 0,
      'ready_for_pickup': 0,
      'out_for_delivery': 0,
      'delivered': 0,
      'cancelled': 0,
    };
    for (final row in orders) {
      final status = (row['status'] ?? 'placed').toString();
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  String _topFeature(List<Map<String, dynamic>> usageEvents) {
    final buckets = <String, int>{};
    for (final event in usageEvents) {
      final name = (event['event_name'] ?? '').toString();
      if (name.isEmpty || name == 'auth_success' || name == 'auth_failure') {
        continue;
      }
      buckets[name] = (buckets[name] ?? 0) + 1;
    }
    if (buckets.isEmpty) return 'n/a';
    final sorted = buckets.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key.replaceAll('_', ' ');
  }

  int _recentCrashCount(List<Map<String, dynamic>> crashReports) {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return crashReports.where((crash) {
      final createdAt =
          DateTime.tryParse((crash['created_at'] ?? '').toString());
      return createdAt != null && createdAt.isAfter(cutoff);
    }).length;
  }
}
