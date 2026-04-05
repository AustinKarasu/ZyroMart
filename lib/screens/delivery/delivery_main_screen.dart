import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../role_selection_screen.dart';
import 'delivery_dashboard_screen.dart';
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
    _DeliveryProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DeliveryProfileScreen extends StatelessWidget {
  const _DeliveryProfileScreen();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Profile')),
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
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryRed,
                  child: Text(
                    user?.name[0] ?? 'D',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? 'Delivery Partner', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(user?.phone ?? '', style: TextStyle(color: AppTheme.textMedium)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat('Rating', '${user?.deliveryRating ?? 0}', Icons.star, AppTheme.warning),
                    _buildStat('Deliveries', '${user?.completedDeliveries ?? 0}', Icons.delivery_dining, AppTheme.success),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Online Status', style: TextStyle(fontWeight: FontWeight.w600)),
                Switch(
                  value: user?.isOnline ?? false,
                  onChanged: (_) {},
                  activeColor: AppTheme.primaryRed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: AppTheme.textMedium),
            title: const Text('Earnings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textLight),
            onTap: () {},
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 4),
          ListTile(
            leading: const Icon(Icons.history, color: AppTheme.textMedium),
            title: const Text('Delivery History'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textLight),
            onTap: () {},
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.swap_horiz, color: AppTheme.textMedium),
            title: const Text('Switch Role'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textLight),
            onTap: () {
              auth.logout();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()), (route) => false);
            },
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: AppTheme.textMedium, fontSize: 13)),
      ],
    );
  }
}
