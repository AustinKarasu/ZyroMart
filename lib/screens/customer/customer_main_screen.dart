import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'customer_home_screen.dart';
import 'customer_orders_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    CustomerHomeScreen(),
    CustomerOrdersScreen(),
    _CustomerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}

class _CustomerProfileScreen extends StatefulWidget {
  const _CustomerProfileScreen();

  @override
  State<_CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<_CustomerProfileScreen> {
  String _appearance = 'Warm Light';
  bool _hideSensitiveItems = false;
  bool _twoFactorEnabled = true;
  bool _marketingNotifications = true;
  bool _orderNotifications = true;
  bool _soundEnabled = true;
  bool _biometricsEnabled = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EC),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 58, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF916113), Color(0xFF1A171C)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      style: IconButton.styleFrom(backgroundColor: Colors.white12),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _showProfileEditor(context, auth),
                      style: IconButton.styleFrom(backgroundColor: Colors.white12),
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 54,
                  backgroundColor: const Color(0xFF9A6A19),
                  child: Text(
                    (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 18),
                Text(user?.name ?? 'Your account', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(user?.phone ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 18)),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(colors: [Color(0xFF6B3700), Color(0xFF965F08)]),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Complete your account setup', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                            SizedBox(height: 6),
                            Text('Add your email and password for faster sign in across devices.', style: TextStyle(color: Colors.white70, height: 1.4)),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () => _showPasswordSetup(context, auth),
                        style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryRed),
                        child: const Text('Set up'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _statCard(Icons.receipt_long, 'Your orders', 'Track live and past orders')),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard(Icons.card_giftcard, 'Gift cards', 'Claim and redeem instantly')),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard(Icons.support_agent, 'Need help?', '24/7 support and FAQs')),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Appearance',
                  children: [
                    _dropdownRow('Theme style', _appearance, ['Warm Light', 'Graphite Dark', 'Solarized', 'System']),
                    _switchRow('Hide sensitive items', 'Hide restricted and wellness-related items from browsing.', _hideSensitiveItems, (value) => setState(() => _hideSensitiveItems = value)),
                    _switchRow('Enable sounds', 'Play sounds for order milestones and rider updates.', _soundEnabled, (value) => setState(() => _soundEnabled = value)),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Your information',
                  children: [
                    _navRow(Icons.location_on_outlined, 'Address book', user?.address.isNotEmpty == true ? user!.address : 'Home, office, and saved places'),
                    _navRow(Icons.favorite_border, 'Your wishlist', 'Save items for later restocks'),
                    _navRow(Icons.payment_outlined, 'Payment methods', 'Cards, UPI, COD, and billing preferences'),
                    _navRow(Icons.receipt_long_outlined, 'GST details', 'Business invoices and saved tax info'),
                    _navRow(Icons.redeem_outlined, 'Promo codes', 'Redeem active offers like FREEDEL, SAVE50, WELCOME100'),
                    _navRow(Icons.card_giftcard_outlined, 'Claim gift card', 'Apply gift balances and campaign rewards'),
                    _navRow(Icons.stars_outlined, 'Collected rewards', 'Loyalty milestones, cashback, and partner perks'),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Security and access',
                  children: [
                    _switchRow('Two-factor verification', 'Keep OTP verification enabled for secure account changes.', _twoFactorEnabled, (value) => setState(() => _twoFactorEnabled = value)),
                    _switchRow('Biometric unlock', 'Use fingerprint or face unlock when supported on device.', _biometricsEnabled, (value) => setState(() => _biometricsEnabled = value)),
                    _navRow(Icons.mail_outline, 'Password login', user?.email.isNotEmpty == true ? user!.email : 'Add email and password for faster login'),
                    _navRow(Icons.privacy_tip_outlined, 'Account privacy', 'Control data visibility and account permissions'),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Preferences',
                  children: [
                    _switchRow('Order notifications', 'Receive rider movement, packing, and delivery alerts.', _orderNotifications, (value) => setState(() => _orderNotifications = value)),
                    _switchRow('Marketing updates', 'Receive new offers, launches, and rewards campaigns.', _marketingNotifications, (value) => setState(() => _marketingNotifications = value)),
                    _navRow(Icons.help_outline, 'Help and support', 'Chat, call, and report delivery or billing issues'),
                    _navRow(Icons.share_outlined, 'Share the app', 'Invite friends and earn referral rewards'),
                    _navRow(Icons.info_outline, 'About ZyroMart', 'Version, company info, and platform details'),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  onTap: auth.logout,
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  leading: const Icon(Icons.logout, color: AppTheme.primaryRed),
                  title: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryRed)),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF23232B), borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35)),
      ]),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ...children,
      ]),
    );
  }

  Widget _navRow(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.textMedium),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  Widget _switchRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _dropdownRow(String title, String value, List<String> options) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox.shrink(),
        items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
        onChanged: (newValue) {
          if (newValue == null) return;
          setState(() => _appearance = newValue);
        },
      ),
    );
  }

  Future<void> _showPasswordSetup(BuildContext context, AuthService auth) async {
    final emailController = TextEditingController(text: auth.currentUser?.email ?? '');
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Set up email and password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password'),
                        validator: (value) => (value == null || value.length < 8) ? 'Minimum 8 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final success = await auth.setupEmailPassword(
                              email: emailController.text,
                              password: passwordController.text,
                            );
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(success ? 'Password login saved' : (auth.errorMessage ?? 'Could not save password'))),
                            );
                          },
                          child: const Text('Save credentials'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showProfileEditor(BuildContext context, AuthService auth) async {
    final user = auth.currentUser;
    if (user == null) return;
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final addressController = TextEditingController(text: user.address);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Edit account details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 12),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final success = await auth.updateProfile(
                        name: nameController.text,
                        email: emailController.text,
                        address: addressController.text,
                        role: user.role,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Profile updated' : (auth.errorMessage ?? 'Could not save profile'))),
                      );
                    },
                    child: const Text('Save changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
