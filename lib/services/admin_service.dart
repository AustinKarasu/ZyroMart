import 'package:flutter/material.dart';

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
}
