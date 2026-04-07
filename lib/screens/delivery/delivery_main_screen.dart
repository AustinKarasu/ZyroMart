import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../services/app_preferences_service.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../shared/notification_center_screen.dart';
import 'delivery_dashboard_screen.dart';
import 'delivery_earnings_screen.dart';
import 'delivery_map_screen.dart';

class DeliveryMainScreen extends StatefulWidget {
  const DeliveryMainScreen({super.key});

  @override
  State<DeliveryMainScreen> createState() => _DeliveryMainScreenState();
}

class _DeliveryMainScreenState extends State<DeliveryMainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    DeliveryDashboardScreen(),
    DeliveryMapScreen(),
    DeliveryEarningsScreen(user: null),
    _DeliveryAccountScreen(),
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
            icon: Icon(Icons.delivery_dining_outlined),
            activeIcon: Icon(Icons.delivery_dining),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
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

// ─── Delivery Agent Account screen ───────────────────────────────────────────

class _DeliveryAccountScreen extends StatefulWidget {
  const _DeliveryAccountScreen();

  @override
  State<_DeliveryAccountScreen> createState() => _DeliveryAccountScreenState();
}

class _DeliveryAccountScreenState extends State<_DeliveryAccountScreen> {
  bool _editing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _startEdit(AuthService auth) {
    final u = auth.currentUser!;
    _nameCtrl.text = u.name;
    _phoneCtrl.text = u.phone;
    _addressCtrl.text = u.address;
    setState(() => _editing = true);
  }

  Future<void> _save(BuildContext context, AuthService auth) async {
    setState(() => _saving = true);
    final user = auth.currentUser!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final success = await auth.updateProfile(
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        role: user.role,
        profileImageUrl: user.profileImageUrl,
        location: user.location,
      );
      if (mounted) {
        setState(() => _editing = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Profile updated'
                  : (auth.errorMessage ?? 'Error saving'),
            ),
            backgroundColor: success ? AppTheme.success : AppTheme.primaryRed,
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
    final orderService = context.watch<OrderService>();
    final messenger = ScaffoldMessenger.of(context);
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final earnings = orderService.earningsFor(
      UserRole.delivery,
      userId: user.id,
    );
    final deliveries = orderService
        .earningsFor(UserRole.delivery, userId: user.id)
        .completedOrders;
    final rating = orderService.deliveryRatingForPartner(user.id);
    final ratingCount = orderService.deliveryRatingCountForPartner(user.id);
    final activeAssignments = orderService.activeOrders
        .where((order) => order.deliveryPersonId == user.id)
        .length;
    final pendingProof = orderService.pendingProofCountForDeliveryPartner(
      user.id,
    );
    final routePings = orderService.routePingCountForDeliveryPartner(user.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
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
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : 'D',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    user.phone,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: user.isOnline
                                          ? AppTheme.success
                                          : Colors.grey.shade600,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      user.isOnline ? 'Online' : 'Offline',
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
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _heroStat('⭐ $rating', 'Rating'),
                            _heroStat('$deliveries', 'Deliveries'),
                            _heroStat(
                              'Rs ${earnings.released.toInt()}',
                              'Earned',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ratingCount == 0
                              ? 'No live ratings yet'
                              : '$ratingCount customer rating${ratingCount == 1 ? '' : 's'} received',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
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
                  onPressed: () => _startEdit(auth),
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
                    _buildEditForm(context, auth),
                  ] else ...[
                    _infoCard('Name', user.name, Icons.person_outline),
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
                      user.address.isNotEmpty ? user.address : 'Not set',
                      Icons.location_on_outlined,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _sectionLabel('Delivery Snapshot'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _statCard(
                        'Active',
                        '$activeAssignments',
                        Icons.local_shipping_outlined,
                      ),
                      _statCard(
                        'Pending Proof',
                        '$pendingProof',
                        Icons.verified_outlined,
                      ),
                      _statCard(
                        'Route Pings',
                        '$routePings',
                        Icons.route_outlined,
                      ),
                      _statCard(
                        'Held',
                        'Rs ${earnings.held.toInt()}',
                        Icons.savings_outlined,
                      ),
                    ],
                  ),
                  _sectionLabel('Availability'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          user.isOnline ? Icons.circle : Icons.circle_outlined,
                          color: user.isOnline ? AppTheme.success : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Online Status',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                user.isOnline
                                    ? 'You are receiving delivery assignments'
                                    : 'You are not receiving assignments',
                                style: const TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: user.isOnline,
                          activeThumbColor: AppTheme.success,
                          onChanged: (val) async {
                            final ok = await auth.setOnlineStatus(val);
                            if (!ok && context.mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    auth.errorMessage ??
                                        'Could not update status',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  _sectionLabel('Preferences'),
                  _switchTile(
                    'Order Notifications',
                    'New assignment alerts',
                    prefs.orderNotifications,
                    prefs.setOrderNotifications,
                  ),
                  _switchTile(
                    'Auto Login',
                    'Stay signed in on this device',
                    prefs.autoLogin,
                    prefs.setAutoLogin,
                  ),
                  _sectionLabel('More'),
                  _actionTile(
                    context,
                    Icons.notifications_none_rounded,
                    'Notification Center',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationCenterScreen(
                            title: 'Delivery Notifications',
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
  }

  Widget _heroStat(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          fontSize: 11,
        ),
      ),
    ],
  );

  Widget _statCard(String label, String value, IconData icon) => Container(
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
        Icon(icon, color: const Color(0xFF1565C0), size: 20),
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
  Widget _buildEditForm(BuildContext context, AuthService auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline),
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
            labelText: 'Home Address',
            prefixIcon: Icon(Icons.home_outlined),
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
                onPressed: _saving ? null : () => _save(context, auth),
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

  Widget _infoCard(String label, String value, IconData icon) => Container(
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
        Icon(icon, size: 20, color: const Color(0xFF1565C0)),
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

  Widget _sectionLabel(String title) => Padding(
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

  Widget _switchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeThumbColor: const Color(0xFF1565C0),
          onChanged: onChanged,
        ),
      ],
    ),
  );

  Widget _actionTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) => Container(
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

  Future<void> _confirmLogout(BuildContext context, AuthService auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
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
