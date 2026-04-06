import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_preferences_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../shared/notification_center_screen.dart';
import 'store_dashboard_screen.dart';
import 'store_orders_screen.dart';
import 'store_products_screen.dart';

class StoreMainScreen extends StatefulWidget {
  const StoreMainScreen({super.key});

  @override
  State<StoreMainScreen> createState() => _StoreMainScreenState();
}

class _StoreMainScreenState extends State<StoreMainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    StoreDashboardScreen(),
    StoreOrdersScreen(),
    StoreProductsScreen(),
    _StoreSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _StoreSettingsScreen extends StatelessWidget {
  const _StoreSettingsScreen();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final preferences = context.watch<AppPreferencesService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Store Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppTheme.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.store, color: AppTheme.primaryRed, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Store owner', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(user?.address.isNotEmpty == true ? user!.address : 'Update store address and radius for serviceability', style: const TextStyle(color: AppTheme.textMedium, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildItem(Icons.storefront_outlined, 'Store name', user?.name ?? 'Configure store identity'),
          _buildItem(Icons.phone, 'Phone', user?.phone ?? 'Add store contact number'),
          _buildItem(Icons.location_on, 'Location', user?.address.isNotEmpty == true ? user!.address : 'Set the exact store address'),
          _buildItem(Icons.my_location_outlined, 'Service radius', 'Order visibility follows the configured delivery radius'),
          _buildTapItem(
            context,
            Icons.notifications_none_rounded,
            'Notification center',
            'Review order updates, payout alerts, and ops messages',
            const NotificationCenterScreen(title: 'Store notifications'),
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            value: preferences.orderNotifications,
            onChanged: preferences.setOrderNotifications,
            title: const Text('Order notifications'),
            subtitle: const Text('Get alerts for new, accepted, and cancelled orders.'),
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            value: preferences.autoLogin,
            onChanged: preferences.setAutoLogin,
            title: const Text('Auto login'),
            subtitle: const Text('Stay signed in on this store device until logout.'),
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.primaryRed),
            title: const Text('Log out'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textLight),
            onTap: auth.logout,
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryRed, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTapItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Widget destination,
  ) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination),
      ),
      child: _buildItem(icon, label, value),
    );
  }
}
