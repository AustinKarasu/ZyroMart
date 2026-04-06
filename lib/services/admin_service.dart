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
  });

  final int totalOrders;
  final int totalProducts;
  final int totalStores;
  final int totalCustomers;
  final int totalDeliveryPartners;
  final double pendingPlatformBalance;
  final double paidPlatformBalance;
  final Map<String, dynamic>? latestMetrics;
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
        latestMetrics: metrics.isEmpty ? null : metrics.first,
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
    );
    notifyListeners();
  }
}
