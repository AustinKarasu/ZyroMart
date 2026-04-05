import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class OnboardingAuthScreen extends StatefulWidget {
  const OnboardingAuthScreen({super.key});

  @override
  State<OnboardingAuthScreen> createState() => _OnboardingAuthScreenState();
}

class _OnboardingAuthScreenState extends State<OnboardingAuthScreen> {
  bool _showAuth = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      child: _showAuth
          ? _ProfessionalAuthCard(onBack: () => setState(() => _showAuth = false))
          : _IntroExperience(onContinue: () => setState(() => _showAuth = true)),
    );
  }
}

class _IntroExperience extends StatelessWidget {
  final VoidCallback onContinue;

  const _IntroExperience({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final highlights = <(IconData, String, String)>[
      (
        Icons.local_shipping_outlined,
        '10-minute delivery feel',
        'Real-time order status, rider flow, and cart-to-checkout UX.'
      ),
      (
        Icons.verified_user_outlined,
        'Phone verified access',
        'Role-based sign in for customers, store owners, and delivery partners.'
      ),
      (
        Icons.storefront_outlined,
        'One platform, three apps',
        'Operations, storefront, and delivery workflows in one polished product.'
      ),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF180B0A), Color(0xFF7A1712), Color(0xFFF26D21)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 860;
                    final hero = _IntroHero(onContinue: onContinue);
                    final card = _IntroHighlights(highlights: highlights);

                    return Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: compact
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                hero,
                                const SizedBox(height: 24),
                                card,
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: hero),
                                const SizedBox(width: 24),
                                Expanded(child: card),
                              ],
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroHero extends StatelessWidget {
  final VoidCallback onContinue;

  const _IntroHero({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'ZYROMART QUICK COMMERCE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Groceries, operations, and delivery in one professional stack.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'A real entry experience with phone login, role-aware access, operational dashboards, and a storefront built to feel closer to the best quick-commerce apps.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.84),
            fontSize: 16,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryRed,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('Get Started'),
            ),
            OutlinedButton(
              onPressed: onContinue,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.32)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ],
    );
  }
}

class _IntroHighlights extends StatelessWidget {
  final List<(IconData, String, String)> highlights;

  const _IntroHighlights({required this.highlights});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Built for daily operations',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ...highlights.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F4EF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE1D4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item.$1, color: AppTheme.primaryRed),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$3,
                          style: const TextStyle(
                            color: AppTheme.textMedium,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalAuthCard extends StatefulWidget {
  final VoidCallback onBack;

  const _ProfessionalAuthCard({required this.onBack});

  @override
  State<_ProfessionalAuthCard> createState() => _ProfessionalAuthCardState();
}

class _ProfessionalAuthCardState extends State<_ProfessionalAuthCard> {
  final _nameController = TextEditingController(text: 'Aayan Karasu');
  final _emailController = TextEditingController(text: 'customer@zyromart.com');
  final _phoneController = TextEditingController(text: '+919876543220');
  final _otpController = TextEditingController();
  UserRole _selectedRole = UserRole.customer;
  bool _isSignUp = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final roleSubtitle = switch (_selectedRole) {
      UserRole.customer => 'Shop the storefront with a verified phone number.',
      UserRole.storeOwner => 'Manage catalog, prep, and live incoming orders.',
      UserRole.delivery => 'Accept trips, navigate routes, and complete deliveries.',
    };

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7EEE8), Color(0xFFFFFAF7)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 32,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 820;
                      final overview = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: widget.onBack,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back'),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Secure access for every role',
                            style: TextStyle(
                              color: AppTheme.textDark,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            roleSubtitle,
                            style: const TextStyle(
                              color: AppTheme.textMedium,
                              fontSize: 15,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _AuthModeSwitch(
                            isSignUp: _isSignUp,
                            onChanged: (value) => setState(() => _isSignUp = value),
                          ),
                          const SizedBox(height: 18),
                          _RoleGrid(
                            selectedRole: _selectedRole,
                            onChanged: (role) {
                              setState(() {
                                _selectedRole = role;
                                _emailController.text = _defaultEmailForRole(role);
                                _phoneController.text = _defaultPhoneForRole(role);
                              });
                              context.read<AuthService>().selectRole(role);
                            },
                          ),
                        ],
                      );

                      final formCard = Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF7F2),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isSignUp ? 'Create your account' : 'Sign in to continue',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              auth.canUseSupabaseAuth
                                  ? 'A real OTP will be sent through Supabase phone authentication.'
                                  : 'Supabase publishable key or phone auth setup is missing, so OTP cannot be sent yet.',
                              style: const TextStyle(
                                color: AppTheme.textMedium,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (_isSignUp) ...[
                              TextField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: Icon(Icons.phone_outlined),
                                hintText: '+91 9876543210',
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: _isSignUp ? 'Email Address (Optional)' : 'Email Address',
                                prefixIcon: const Icon(Icons.alternate_email),
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (auth.otpRequested)
                              TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                decoration: const InputDecoration(
                                  labelText: '6-digit OTP',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                              ),
                            if (auth.errorMessage != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                auth.errorMessage!,
                                style: const TextStyle(
                                  color: AppTheme.primaryRed,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            if (auth.statusMessage != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                auth.statusMessage!,
                                style: const TextStyle(
                                  color: Color(0xFF8A5200),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        if (!auth.otpRequested) {
                                          final success = await auth.requestOtp(
                                            phone: _phoneController.text,
                                            email: _emailController.text,
                                            name: _nameController.text,
                                            role: _selectedRole,
                                          );
                                          if (success && context.mounted) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  auth.statusMessage ??
                                                      'OTP sent to ${_phoneController.text.trim()}',
                                                ),
                                              ),
                                            );
                                          }
                                        } else {
                                          final success = await auth.verifyOtp(_otpController.text);
                                          if (!success &&
                                              context.mounted &&
                                              auth.errorMessage == null) {
                                            messenger.showSnackBar(
                                              const SnackBar(content: Text('Could not verify OTP')),
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryRed,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(auth.otpRequested ? 'Verify and Continue' : 'Send OTP'),
                              ),
                            ),
                          ],
                        ),
                      );

                      return compact
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                overview,
                                const SizedBox(height: 24),
                                formCard,
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: overview),
                                const SizedBox(width: 24),
                                Expanded(child: formCard),
                              ],
                            );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _defaultEmailForRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'customer@zyromart.com';
      case UserRole.storeOwner:
        return 'owner@zyromart.com';
      case UserRole.delivery:
        return 'delivery@zyromart.com';
    }
  }

  String _defaultPhoneForRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return '+919876543220';
      case UserRole.storeOwner:
        return '+919876543210';
      case UserRole.delivery:
        return '+919876543215';
    }
  }
}

class _AuthModeSwitch extends StatelessWidget {
  final bool isSignUp;
  final ValueChanged<bool> onChanged;

  const _AuthModeSwitch({
    required this.isSignUp,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeChip(
              label: 'Sign In',
              selected: !isSignUp,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ModeChip(
              label: 'Sign Up',
              selected: isSignUp,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppTheme.textDark : AppTheme.textMedium,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _RoleGrid extends StatelessWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;

  const _RoleGrid({
    required this.selectedRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final roles = <(UserRole, String, IconData, String)>[
      (UserRole.customer, 'Customer', Icons.shopping_bag_outlined, 'Personal shopping'),
      (UserRole.storeOwner, 'Store Owner', Icons.store_mall_directory_outlined, 'Catalog and operations'),
      (UserRole.delivery, 'Delivery Agent', Icons.two_wheeler_outlined, 'Trips and fulfillment'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: roles.map((entry) {
        final selected = selectedRole == entry.$1;
        return InkWell(
          onTap: () => onChanged(entry.$1),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF211311) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? const Color(0xFF211311) : const Color(0xFFE8DED5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(entry.$3, color: selected ? Colors.white : AppTheme.primaryRed),
                const SizedBox(height: 14),
                Text(
                  entry.$2,
                  style: TextStyle(
                    color: selected ? Colors.white : AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.$4,
                  style: TextStyle(
                    color: selected ? Colors.white70 : AppTheme.textMedium,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
