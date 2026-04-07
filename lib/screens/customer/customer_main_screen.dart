import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_preferences_service.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../theme/app_theme.dart';
import '../shared/notification_center_screen.dart';
import 'customer_account_tools_screen.dart';
import 'customer_home_screen.dart';
import 'customer_orders_screen.dart';
import 'restock_subscriptions_screen.dart';

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
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Account',
          ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white12,
                      ),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 54,
                  backgroundColor: const Color(0xFF9A6A19),
                  backgroundImage: (user?.profileImageUrl?.isNotEmpty ?? false)
                      ? NetworkImage(user!.profileImageUrl!)
                      : null,
                  child: (user?.profileImageUrl?.isNotEmpty ?? false)
                      ? null
                      : Text(
                          (user?.name.isNotEmpty == true ? user!.name[0] : 'U')
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(height: 18),
                Text(
                  user?.name ?? 'Your account',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user?.phone ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B3700), Color(0xFF965F08)],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Faster sign-in setup',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Add your email and password after OTP verification for easier future logins.',
                              style: TextStyle(
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () => _showPasswordSetup(context, auth),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryRed,
                        ),
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
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 44) / 2,
                      child: _statCard(
                        Icons.receipt_long,
                        'Your orders',
                        'Track active and completed orders',
                      ),
                    ),
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 44) / 2,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationCenterScreen(
                              title: 'Customer notifications',
                            ),
                          ),
                        ),
                        child: _statCard(
                          Icons.notifications_none_rounded,
                          'Notifications',
                          'Order updates, promos, and delivery events',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 32,
                      child: _statCard(
                        Icons.support_agent,
                        'Need help?',
                        'Support, refunds, and order help',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Appearance',
                  children: [
                    _themeRow(context, preferences),
                    _switchRow(
                      context,
                      title: 'Hide sensitive items',
                      subtitle:
                          'Hide wellness and restricted products from browse screens.',
                      value: preferences.hideSensitiveItems,
                      onChanged: preferences.setHideSensitiveItems,
                    ),
                    _switchRow(
                      context,
                      title: 'Enable sounds',
                      subtitle:
                          'Play a light system bell sound when sounds are enabled.',
                      value: preferences.soundEnabled,
                      onChanged: preferences.setSoundEnabled,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Your information',
                  children: [
                    _navRow(
                      context,
                      Icons.location_on_outlined,
                      'Address book',
                      user?.address.isNotEmpty == true
                          ? user!.address
                          : 'Manage your saved delivery address',
                      'Add, update, and choose saved delivery locations.',
                      destination: AddressBookScreen(
                        userId: user?.id ?? 'guest',
                        initialAddress: user?.address ?? '',
                      ),
                    ),
                    _navRow(
                      context,
                      Icons.favorite_border,
                      'Your wishlist',
                      'Save products you want to buy later',
                      'Wishlist items stay ready for future baskets.',
                      destination: WishlistScreen(userId: user?.id ?? 'guest'),
                    ),
                    _navRow(
                      context,
                      Icons.payment_outlined,
                      'Payment methods',
                      'Manage UPI, COD, and billing preferences',
                      'Saved payment preferences appear here for faster checkout.',
                      destination: PaymentMethodsScreen(
                        userId: user?.id ?? 'guest',
                      ),
                    ),
                    _navRow(
                      context,
                      Icons.receipt_long_outlined,
                      'GST details',
                      'Saved business invoice details',
                      'Maintain invoice-ready GST data for eligible orders.',
                      destination: GstDetailsScreen(
                        userId: user?.id ?? 'guest',
                      ),
                    ),
                    _navRow(
                      context,
                      Icons.redeem_outlined,
                      'Promo codes',
                      'Only verified store and platform coupons appear here',
                      'Active verified coupons are listed here once issued.',
                      destination: PromoCodesScreen(
                        userId: user?.id ?? 'guest',
                      ),
                    ),
                    _navRow(
                      context,
                      Icons.autorenew_rounded,
                      'Auto-restock',
                      'Keep essentials on a daily, weekly, or monthly cadence',
                      'Restock subscriptions are account-scoped and sync through the backend.',
                      destination: const RestockSubscriptionsScreen(),
                    ),
                    _navRow(
                      context,
                      Icons.card_giftcard_outlined,
                      'Claim gift card',
                      'Apply available gift card balances',
                      'Redeem store credit or gift card balances from this section.',
                      destination: GiftCardScreen(userId: user?.id ?? 'guest'),
                    ),
                    _navRow(
                      context,
                      Icons.stars_outlined,
                      'Collected rewards',
                      'Track loyalty and order rewards',
                      'Monitor loyalty, gift balances, and earned rewards.',
                      destination: RewardsScreen(userId: user?.id ?? 'guest'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Security and access',
                  children: [
                    _switchRow(
                      context,
                      title: 'Two-factor verification',
                      subtitle:
                          'Require OTP verification during sensitive account changes.',
                      value: preferences.twoFactorEnabled,
                      onChanged: preferences.setTwoFactorEnabled,
                    ),
                    _switchRow(
                      context,
                      title: 'Biometric unlock',
                      subtitle:
                          'Use biometric unlock when supported on this device.',
                      value: preferences.biometricUnlock,
                      onChanged: (value) =>
                          _handleBiometricToggle(context, preferences, value),
                    ),
                    _switchRow(
                      context,
                      title: 'Auto login',
                      subtitle:
                          'Stay signed in on this device until you log out manually.',
                      value: preferences.autoLogin,
                      onChanged: preferences.setAutoLogin,
                    ),
                    _navRow(
                      context,
                      Icons.mail_outline,
                      'Password login',
                      user?.email.isNotEmpty == true
                          ? user!.email
                          : 'No email password configured yet',
                      'Manage email-based login after your OTP account is verified.',
                      destination: const PasswordLoginSettingsScreen(),
                    ),
                    _navRow(
                      context,
                      Icons.privacy_tip_outlined,
                      'Account privacy',
                      'Control account safety and personal data preferences',
                      'Privacy and access behavior for this device and account.',
                      destination: const PrivacyScreen(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Preferences',
                  children: [
                    _switchRow(
                      context,
                      title: 'Order notifications',
                      subtitle:
                          'Receive preparation, dispatch, and delivery updates.',
                      value: preferences.orderNotifications,
                      onChanged: preferences.setOrderNotifications,
                    ),
                    _switchRow(
                      context,
                      title: 'Marketing updates',
                      subtitle:
                          'Receive new launches, store campaigns, and rewards.',
                      value: preferences.marketingNotifications,
                      onChanged: preferences.setMarketingNotifications,
                    ),
                    _navRow(
                      context,
                      Icons.help_outline,
                      'Help and support',
                      'Chat, call, or report an issue',
                      'Support options, issue reporting, and order help live here.',
                      destination: const SupportScreen(),
                    ),
                    _navRow(
                      context,
                      Icons.share_outlined,
                      'Share the app',
                      'Share ZyroMart with friends and family',
                      'Invite others using your preferred share method.',
                      destination: const ShareAppScreen(),
                    ),
                    _navRow(
                      context,
                      Icons.info_outline,
                      'About ZyroMart',
                      'App information and version details',
                      'Version, build details, and company information.',
                      destination: const AboutZyroMartScreen(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  onTap: auth.logout,
                  tileColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  leading: const Icon(Icons.logout, color: AppTheme.primaryRed),
                  title: const Text(
                    'Log out',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryRed,
                    ),
                  ),
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
      title: const Text(
        'Theme style',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Text('Apply Light, Dark, or System theme instantly.'),
      trailing: DropdownButton<String>(
        value: current,
        underline: const SizedBox.shrink(),
        items: const [
          DropdownMenuItem(value: 'Light', child: Text('Light')),
          DropdownMenuItem(value: 'Dark', child: Text('Dark')),
          DropdownMenuItem(value: 'System', child: Text('System')),
        ],
        onChanged: (newValue) async {
          if (newValue == null) return;
          final mode = switch (newValue) {
            'Dark' => ThemeMode.dark,
            'System' => ThemeMode.system,
            _ => ThemeMode.light,
          };
          await preferences.setThemeMode(mode);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Theme changed to $newValue.')),
          );
        },
      ),
    );
  }

  Widget _statCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF23232B),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _navRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String body, {
    Widget? destination,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.textMedium),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              destination ??
              _InfoDetailScreen(title: title, subtitle: subtitle, body: body),
        ),
      ),
    );
  }

  Widget _switchRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required Future<void> Function(bool) onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: (next) async {
        await onChanged(next);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title ${next ? 'enabled' : 'disabled'}')),
        );
      },
    );
  }

  Future<void> _handleBiometricToggle(
    BuildContext context,
    AppPreferencesService preferences,
    bool value,
  ) async {
    if (value) {
      final supported = await BiometricService.isSupported();
      if (!supported) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Biometric authentication is not available on this device.',
            ),
          ),
        );
        return;
      }
      final authenticated = await BiometricService.authenticate(
        reason: 'Authenticate to enable biometric unlock for ZyroMart',
      );
      if (!authenticated) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric verification was not completed.'),
          ),
        );
        return;
      }
    }
    await preferences.setBiometricUnlock(value);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Biometric unlock ${value ? 'enabled' : 'disabled'}'),
      ),
    );
  }

  Future<void> _showPasswordSetup(
    BuildContext context,
    AuthService auth,
  ) async {
    final emailController = TextEditingController(
      text: auth.currentUser?.email ?? '',
    );
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Set up email and password',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                        (value == null || !value.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) => (value == null || value.length < 8)
                        ? 'Minimum 8 characters'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                    ),
                    validator: (value) => value != passwordController.text
                        ? 'Passwords do not match'
                        : null,
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
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Password login saved'
                                  : (auth.errorMessage ??
                                        'Could not save password'),
                            ),
                          ),
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

  Future<void> _showProfileEditor(
    BuildContext context,
    AuthService auth,
  ) async {
    final user = auth.currentUser;
    if (user == null) return;
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final addressController = TextEditingController(text: user.address);
    final photoController = TextEditingController(
      text: user.profileImageUrl ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE9D4B0),
                  backgroundImage: photoController.text.trim().isNotEmpty
                      ? NetworkImage(photoController.text.trim())
                      : null,
                  child: photoController.text.trim().isNotEmpty
                      ? null
                      : const Icon(
                          Icons.camera_alt_outlined,
                          color: AppTheme.textDark,
                        ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Change profile details',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: photoController,
                  decoration: const InputDecoration(
                    labelText: 'Profile photo URL',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone number'),
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
                        profileImageUrl: photoController.text.trim(),
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Profile updated'
                                : (auth.errorMessage ??
                                      'Could not save profile'),
                          ),
                        ),
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

class _InfoDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String body;

  const _InfoDetailScreen({
    required this.title,
    required this.subtitle,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Text(body, style: const TextStyle(height: 1.6)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'This section is now connected in-app and opens as its own screen instead of a dead tap target. Extend the stored data here as your live backend records grow.',
                style: TextStyle(height: 1.5, color: AppTheme.textMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
