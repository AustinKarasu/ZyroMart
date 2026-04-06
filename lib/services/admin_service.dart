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
      ]);

      final orders = results[0];
      final products = results[1];
      final stores = results[2];
      final profiles = results[3];
      final platformLedger = results[4];
      final metrics = results[5];
      final latest = metrics.isEmpty ? null : metrics.first;

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
        recentOperationalEvents: _buildOperationalEvents(orders),
        liveSignals: {
          'pending_orders': orders
              .where((row) => row['status'] != 'delivered' && row['status'] != 'cancelled')
              .length,
          'proof_of_delivery_ready': latest?['completed_orders'] ?? 0,
          'active_customers': latest?['active_customers'] ?? 0,
          'active_delivery_partners': latest?['active_delivery_partners'] ?? 0,
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
    _errorMessage = 'Running in local owner mode. Live Supabase admin access is not available for this session.';
    final completedOrders = MockData.sampleOrders.where((o) => o.status == OrderStatus.delivered).length;
    final pendingOrders = MockData.sampleOrders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).length;
    final grossValue = MockData.sampleOrders.fold<double>(0, (sum, order) => sum + order.grandTotal);
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
        'delivery_payout_due': MockData.sampleOrders.fold<double>(0, (sum, order) => sum + order.deliveryFee + order.deliveryTip),
        'store_payout_due': grossValue * 0.95,
        'completed_orders': completedOrders,
        'cancelled_orders': MockData.sampleOrders.where((o) => o.status == OrderStatus.cancelled).length,
        'pending_orders': pendingOrders,
      },
      recentOperationalEvents: MockData.sampleOrders.take(6).map((order) {
        final status = order.statusLabel;
        return {
          'title': 'Order ${order.id}',
          'subtitle': '$status • ${order.customerName}',
          'color': _eventColorForStatus(order.status.name),
        };
      }).toList(),
      liveSignals: {
        'pending_orders': pendingOrders,
        'proof_of_delivery_ready': completedOrders,
        'active_customers': 1,
        'active_delivery_partners': MockData.deliveryPersons.where((item) => item.isOnline).length,
      },
      orderStatusCounts: {
        'placed': MockData.sampleOrders.where((o) => o.status == OrderStatus.placed).length,
        'confirmed': MockData.sampleOrders.where((o) => o.status == OrderStatus.confirmed).length,
        'preparing': MockData.sampleOrders.where((o) => o.status == OrderStatus.preparing).length,
        'ready_for_pickup': MockData.sampleOrders.where((o) => o.status == OrderStatus.readyForPickup).length,
        'out_for_delivery': MockData.sampleOrders.where((o) => o.status == OrderStatus.outForDelivery).length,
        'delivered': completedOrders,
        'cancelled': MockData.sampleOrders.where((o) => o.status == OrderStatus.cancelled).length,
      },
    );
    notifyListeners();
  }

  List<Map<String, dynamic>> _buildOperationalEvents(List<Map<String, dynamic>> orders) {
    final sorted = [...orders]
      ..sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
    return sorted.take(8).map((row) {
      final status = (row['status'] ?? 'placed').toString();
      return {
        'title': 'Order ${(row['order_number'] ?? row['id'] ?? '').toString()}',
        'subtitle': '${status.replaceAll('_', ' ')} • ${(row['customer_name'] ?? 'Customer').toString()}',
        'color': _eventColorForStatus(status),
      };
    }).toList();
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
}
