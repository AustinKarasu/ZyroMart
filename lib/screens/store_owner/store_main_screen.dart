import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_preferences_service.dart';
import '../../services/auth_service.dart';
import '../../services/mock_data.dart';
import '../../services/order_service.dart';
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
          _buildEditableItem(
            context,
            Icons.storefront_outlined,
            'Store name',
            user?.name ?? 'Configure store identity',
            onTap: () => _showStoreEditor(context, auth),
          ),
          _buildEditableItem(
            context,
            Icons.phone,
            'Phone',
            user?.phone ?? 'Add store contact number',
            onTap: () => _showStoreEditor(context, auth),
          ),
          _buildEditableItem(
            context,
            Icons.location_on,
            'Location',
            user?.address.isNotEmpty == true ? user!.address : 'Set the exact store address',
            onTap: () => _showStoreEditor(context, auth),
          ),
          _buildEditableItem(
            context,
            Icons.my_location_outlined,
            'Service radius',
            'Order visibility follows the configured delivery radius',
            onTap: () => _showRadiusEditor(context),
          ),
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

  Widget _buildEditableItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: _buildItem(icon, label, value),
    );
  }

  Future<void> _showStoreEditor(BuildContext context, AuthService auth) async {
    final user = auth.currentUser;
    if (user == null) return;
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final addressController = TextEditingController(text: user.address);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit store settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Store name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final success = await auth.updateProfile(
                    name: nameController.text,
                    address: addressController.text,
                    phone: phoneController.text,
                    role: user.role,
                    profileImageUrl: user.profileImageUrl,
                    location: user.location,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Store settings updated'
                            : (auth.errorMessage ?? 'Could not update store settings'),
                      ),
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRadiusEditor(BuildContext context) async {
    final orderService = context.read<OrderService>();
    final auth = context.read<AuthService>();
    final storeOwner = auth.currentUser;
    if (storeOwner == null) return;
    final ownerStore = MockData.stores.firstWhere(
      (store) => store.ownerId == storeOwner.id,
      orElse: () => MockData.stores.first,
    );
    final currentRadius = orderService.radiusForStore(ownerStore.id);
    final controller =
        TextEditingController(text: currentRadius.toStringAsFixed(1));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Update service radius',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Radius in km',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final value = double.tryParse(controller.text.trim());
                  if (value == null) return;
                  orderService.updateStoreRadius(ownerStore.id, value);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Service radius updated')),
                  );
                },
                child: const Text('Save radius'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
