import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_preferences_service.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../shared/notification_center_screen.dart';
import 'store_analytics_screen.dart';
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
    StoreAnalyticsScreen(),
    _StoreAccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

// ─── Account / Profile screen for store owners ───────────────────────────────

class _StoreAccountScreen extends StatefulWidget {
  const _StoreAccountScreen();

  @override
  State<_StoreAccountScreen> createState() => _StoreAccountScreenState();
}

class _StoreAccountScreenState extends State<_StoreAccountScreen> {
  bool _editing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _storeNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _storeNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _storeNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _startEdit(AuthService auth, Map<String, dynamic>? storeRow) {
    final user = auth.currentUser!;
    _nameCtrl.text = user.name;
    _storeNameCtrl.text = (storeRow?['name'] ?? '').toString();
    _phoneCtrl.text = user.phone;
    _addressCtrl.text = (storeRow?['address'] ?? user.address).toString();
    setState(() => _editing = true);
  }

  Future<void> _save(
    BuildContext context,
    AuthService auth,
    String storeId,
  ) async {
    setState(() => _saving = true);
    final user = auth.currentUser!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.updateProfile(
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        role: user.role,
        profileImageUrl: user.profileImageUrl,
        location: user.location,
      );
      if (SupabaseService.isInitialized && storeId.isNotEmpty) {
        await SupabaseService.upsertOwnerStore(
          ownerId: user.id,
          name: _storeNameCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          latitude: user.location.latitude,
          longitude: user.location.longitude,
          phone: _phoneCtrl.text.trim(),
        );
      }
      if (mounted) {
        setState(() => _editing = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final prefs = context.watch<AppPreferencesService>();
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>?>(
      future: SupabaseService.isInitialized
          ? SupabaseService.getStoreByOwner(user.id)
          : Future.value(null),
      builder: (context, snap) {
        final storeRow = snap.data;
        final storeId = (storeRow?['id'] ?? '').toString();
        final storeName = (storeRow?['name'] ?? user.name).toString();
        final storeAddress = (storeRow?['address'] ?? user.address).toString();
        final isOpen = storeRow?['is_open'] as bool? ?? true;
        final totalOrders = (storeRow?['total_orders'] ?? 0) as int;
        final totalRevenue = ((storeRow?['total_revenue'] ?? 0) as num).toDouble();

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FA),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFB71C1C), Color(0xFF7F0000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                  child: Text(
                                    storeName.isNotEmpty
                                        ? storeName[0].toUpperCase()
                                        : 'S',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        storeName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        user.name,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOpen
                                              ? AppTheme.success
                                              : Colors.grey,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          isOpen ? 'Open' : 'Closed',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (!_editing)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => _startEdit(auth, storeRow),
                    ),
                ],
                title: _editing ? const Text('Edit Profile') : null,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_editing) ...[
                        _buildEditForm(context, auth, storeId),
                      ] else ...[
                        _infoCard(
                          'Owner Name',
                          user.name,
                          Icons.person_outline,
                        ),
                        _infoCard(
                          'Store Name',
                          storeName,
                          Icons.store_outlined,
                        ),
                        _infoCard(
                          'Phone',
                          user.phone.isNotEmpty ? user.phone : 'Not set',
                          Icons.phone_outlined,
                        ),
                        _infoCard(
                          'Email',
                          user.email.isNotEmpty ? user.email : 'Not set',
                          Icons.email_outlined,
                        ),
                        _infoCard(
                          'Address',
                          storeAddress.isNotEmpty ? storeAddress : 'Not set',
                          Icons.location_on_outlined,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _sectionHeader('Store Performance'),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _statCard('Orders', '$totalOrders', Icons.receipt_long_outlined),
                          _statCard('Revenue', 'Rs ${totalRevenue.toInt()}', Icons.payments_outlined),
                          _statCard('Status', isOpen ? 'Open' : 'Closed', Icons.storefront_outlined),
                          _statCard('Owner', user.name, Icons.person_outline),
                        ],
                      ),
                      _sectionHeader('Store Settings'),
                      _settingsTile(
                        context,
                        icon: Icons.open_in_new,
                        title: 'Store Open/Closed',
                        subtitle: isOpen
                            ? 'Your store is accepting orders'
                            : 'Your store is closed',
                        trailing: Switch.adaptive(
                          value: isOpen,
                          activeThumbColor: AppTheme.primaryRed,
                          onChanged: storeId.isEmpty
                              ? null
                              : (val) async {
                                  if (SupabaseService.isInitialized) {
                                    await SupabaseService.updateStore(storeId, {
                                      'is_open': val,
                                    });
                                    setState(() {});
                                  }
                                },
                        ),
                      ),
                      _settingsTile(
                        context,
                        icon: Icons.notifications_outlined,
                        title: 'Order Notifications',
                        subtitle: 'Alerts for new and cancelled orders',
                        trailing: Switch.adaptive(
                          value: prefs.orderNotifications,
                          activeThumbColor: AppTheme.primaryRed,
                          onChanged: prefs.setOrderNotifications,
                        ),
                      ),
                      _settingsTile(
                        context,
                        icon: Icons.login_outlined,
                        title: 'Auto Login',
                        subtitle: 'Stay signed in on this device',
                        trailing: Switch.adaptive(
                          value: prefs.autoLogin,
                          activeThumbColor: AppTheme.primaryRed,
                          onChanged: prefs.setAutoLogin,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _sectionHeader('More'),
                      _actionTile(
                        context,
                        Icons.notifications_none_rounded,
                        'Notification Center',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationCenterScreen(
                                title: 'Store Notifications',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmLogout(context, auth),
                          icon: const Icon(
                            Icons.logout,
                            color: AppTheme.primaryRed,
                          ),
                          label: const Text(
                            'Log Out',
                            style: TextStyle(
                              color: AppTheme.primaryRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryRed),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryRed, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMedium, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(
    BuildContext context,
    AuthService auth,
    String storeId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Your Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _storeNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Store Name',
            prefixIcon: Icon(Icons.store_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Store Address',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _editing = false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : () => _save(context, auth, storeId),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textMedium,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMedium, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _actionTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textMedium),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: AppTheme.textLight,
        ),
        onTap: onTap,
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthService auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out of your store account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) auth.logout();
  }
}



