import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_preferences_service.dart';
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

class _CustomerProfileScreen extends StatelessWidget {
  const _CustomerProfileScreen();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final preferences = context.watch<AppPreferencesService>();
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
                Text(
                  user?.name ?? 'Your account',
                  style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  user?.phone ?? '',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 18),
                ),
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
                            Text('Faster sign-in setup', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                            SizedBox(height: 6),
                            Text('Add your email and password after OTP verification for easier future logins.', style: TextStyle(color: Colors.white70, height: 1.4)),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () => _showPasswordSetup(context, auth),
                        style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryRed),
                        child: const Text('Manage'),
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
                    Expanded(child: _statCard(Icons.receipt_long, 'Your orders', 'Track active and completed orders')),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard(Icons.card_giftcard, 'Gift cards', 'Store credit and rewards when available')),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard(Icons.support_agent, 'Need help?', 'Support, refunds, and order help')),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Appearance',
                  children: [
                    _themeRow(context, preferences),
                    _switchRow(
                      'Hide sensitive items',
                      'Hide wellness and restricted products from browse screens.',
                      preferences.hideSensitiveItems,
                      preferences.setHideSensitiveItems,
                    ),
                    _switchRow(
                      'Enable sounds',
                      'Play a light system bell sound when sounds are enabled.',
                      preferences.soundEnabled,
                      preferences.setSoundEnabled,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Your information',
                  children: [
                    _navRow(context, Icons.location_on_outlined, 'Address book', user?.address.isNotEmpty == true ? user!.address : 'Manage your saved delivery address'),
                    _navRow(context, Icons.favorite_border, 'Your wishlist', 'Save products you want to buy later'),
                    _navRow(context, Icons.payment_outlined, 'Payment methods', 'Manage UPI, COD, and billing preferences'),
                    _navRow(context, Icons.receipt_long_outlined, 'GST details', 'Saved business invoice details'),
                    _navRow(context, Icons.redeem_outlined, 'Promo codes', 'Only verified store and platform coupons appear here'),
                    _navRow(context, Icons.card_giftcard_outlined, 'Claim gift card', 'Apply available gift card balances'),
                    _navRow(context, Icons.stars_outlined, 'Collected rewards', 'Track loyalty and order rewards'),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Security and access',
                  children: [
                    _switchRow(
                      'Two-factor verification',
                      'Require OTP verification during sensitive account changes.',
                      preferences.twoFactorEnabled,
                      preferences.setTwoFactorEnabled,
                    ),
                    _switchRow(
                      'Biometric unlock',
                      'Use biometric unlock when supported on this device.',
                      preferences.biometricUnlock,
                      preferences.setBiometricUnlock,
                    ),
                    _switchRow(
                      'Auto login',
                      'Stay signed in on this device until you log out manually.',
                      preferences.autoLogin,
                      preferences.setAutoLogin,
                    ),
                    _navRow(context, Icons.mail_outline, 'Password login', user?.email.isNotEmpty == true ? user!.email : 'No email password configured yet'),
                    _navRow(context, Icons.privacy_tip_outlined, 'Account privacy', 'Control account safety and personal data preferences'),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Preferences',
                  children: [
                    _switchRow(
                      'Order notifications',
                      'Receive preparation, dispatch, and delivery updates.',
                      preferences.orderNotifications,
                      preferences.setOrderNotifications,
                    ),
                    _switchRow(
                      'Marketing updates',
                      'Receive new launches, store campaigns, and rewards.',
                      preferences.marketingNotifications,
                      preferences.setMarketingNotifications,
                    ),
                    _navRow(context, Icons.help_outline, 'Help and support', 'Chat, call, or report an issue'),
                    _navRow(context, Icons.share_outlined, 'Share the app', 'Share ZyroMart with friends and family'),
                    _navRow(context, Icons.info_outline, 'About ZyroMart', 'App information and version details'),
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

  Widget _themeRow(BuildContext context, AppPreferencesService preferences) {
    final current = switch (preferences.themeMode) {
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Theme style', style: TextStyle(fontWeight: FontWeight.w600)),
      trailing: DropdownButton<String>(
        value: current,
        underline: const SizedBox.shrink(),
        items: const [
          DropdownMenuItem(value: 'Light', child: Text('Light')),
          DropdownMenuItem(value: 'Dark', child: Text('Dark')),
          DropdownMenuItem(value: 'System', child: Text('System')),
        ],
        onChanged: (newValue) {
          if (newValue == null) return;
          final mode = switch (newValue) {
            'Dark' => ThemeMode.dark,
            'System' => ThemeMode.system,
            _ => ThemeMode.light,
          };
          preferences.setThemeMode(mode);
        },
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

  Widget _navRow(BuildContext context, IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.textMedium),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title is available in this account section.')),
        );
      },
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

  Future<void> _showPasswordSetup(BuildContext context, AuthService auth) async {
    final emailController = TextEditingController(text: auth.currentUser?.email ?? '');
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm password'),
                    validator: (value) => value != passwordController.text ? 'Passwords do not match' : null,
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
          ),
        );
      },
    );
  }

  Future<void> _showProfileEditor(BuildContext context, AuthService auth) async {
    final user = auth.currentUser;
    if (user == null) return;
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
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
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFE9D4B0),
                  child: Icon(Icons.camera_alt_outlined, color: AppTheme.textDark),
                ),
                const SizedBox(height: 10),
                const Text('Change profile details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 12),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone number')),
                const SizedBox(height: 12),
                TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
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
