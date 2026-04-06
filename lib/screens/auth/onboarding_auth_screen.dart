import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
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
          ? _ProfessionalAuthCard(
              onBack: () => setState(() => _showAuth = false),
            )
          : _IntroExperience(
              onContinue: () => setState(() => _showAuth = true),
            ),
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
        Icons.schedule,
        '24-hour delivery promise',
        'Round-the-clock storefront, fulfillment, and account access built for real use.',
      ),
      (
        Icons.verified_user_outlined,
        'Verified access only',
        'Phone verification for signup and profile-backed access for customer, store owner, and delivery.',
      ),
      (
        Icons.storefront_outlined,
        'One platform, separate operations',
        'Customer, store, delivery, and admin experiences stay connected while keeping clean boundaries.',
      ),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1117), Color(0xFF171E28), Color(0xFF202A36)],
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
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: compact
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                const SizedBox(width: 16),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'ZYROMART QUICK COMMERCE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Groceries, operations, and delivery in one professional stack.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Fast access to customer, store, and delivery workflows with secure OTP and password login.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.84),
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: onContinue,
              child: const Text('Get Started'),
            ),
            OutlinedButton(
              onPressed: onContinue,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.32)),
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
        color: const Color(0xFFF6F7FA),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
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
                      children: [
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.$3,
                          style: const TextStyle(
                            color: AppTheme.textMedium,
                            height: 1.35,
                            fontSize: 13,
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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  UserRole _selectedRole = UserRole.customer;
  bool _isSignUp = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final roleSubtitle = switch (_selectedRole) {
      UserRole.customer =>
        'Shop the storefront with verified signup and role-safe password login.',
      UserRole.storeOwner =>
        'Manage catalog, prep, radius, and live incoming orders.',
      UserRole.delivery =>
        'Accept trips, navigate routes, and complete deliveries.',
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
                            onChanged: (value) =>
                                setState(() => _isSignUp = value),
                          ),
                          const SizedBox(height: 18),
                          _RoleGrid(
                            selectedRole: _selectedRole,
                            onChanged: (role) {
                              setState(() => _selectedRole = role);
                              context.read<AuthService>().selectRole(role);
                            },
                          ),
                          const SizedBox(height: 18),
                          if (!_isSignUp)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3ECE5),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _ModeChip(
                                      label: 'OTP Login',
                                      selected: !auth.isPasswordLogin,
                                      onTap: () => context
                                          .read<AuthService>()
                                          .setPasswordMode(false),
                                    ),
                                  ),
                                  Expanded(
                                    child: _ModeChip(
                                      label: 'Password',
                                      selected: auth.isPasswordLogin,
                                      onTap: () => context
                                          .read<AuthService>()
                                          .setPasswordMode(true),
                                    ),
                                  ),
                                ],
                              ),
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
                          children: [
                            Text(
                              _isSignUp
                                  ? 'Create your account'
                                  : 'Sign in to continue',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isSignUp
                                  ? 'Email is required for signup. We verify the phone number first and attach the password immediately after OTP verification.'
                                  : auth.isPasswordLogin
                                  ? 'Use your email and password. Role access is resolved from your live profile after sign-in.'
                                  : 'Phone OTP sign in does not require an email field.',
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
                              if (_selectedRole == UserRole.storeOwner) ...[
                                TextField(
                                  controller: _storeNameController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Store Name',
                                    prefixIcon: Icon(Icons.storefront_outlined),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _storeAddressController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    labelText: 'Store Location',
                                    prefixIcon: Icon(
                                      Icons.location_on_outlined,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                            ],
                            if (_isSignUp || !auth.isPasswordLogin)
                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                              ),
                            if (_isSignUp || auth.isPasswordLogin) ...[
                              const SizedBox(height: 14),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: Icon(Icons.alternate_email),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                              ),
                            ],
                            if (_isSignUp) ...[
                              const SizedBox(height: 14),
                              TextField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: Icon(Icons.lock_person_outlined),
                                ),
                              ),
                            ],
                            if (auth.otpRequested) ...[
                              const SizedBox(height: 14),
                              TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                decoration: const InputDecoration(
                                  labelText: '6-digit OTP',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                              ),
                            ],
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
                                    : () => _submit(context, auth),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(_buttonLabel(auth)),
                              ),
                            ),
                          ],
                        ),
                      );

                      return compact
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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

  Future<void> _submit(BuildContext context, AuthService auth) async {
    final messenger = ScaffoldMessenger.of(context);

    if (!_isSignUp && auth.isPasswordLogin) {
      if (!_emailController.text.contains('@')) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Enter a valid email address')),
        );
        return;
      }
      final success = await auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
      );
      if (success && context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Signed in with password')),
        );
      }
      return;
    }

    if (!auth.otpRequested) {
      if (_isSignUp) {
        if (_nameController.text.trim().isEmpty) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Enter your full name')),
          );
          return;
        }
        if (!_emailController.text.contains('@')) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Enter a valid email address')),
          );
          return;
        }
        if (_passwordController.text.length < 8) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Password must be at least 8 characters'),
            ),
          );
          return;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Passwords do not match')),
          );
          return;
        }
        if (_selectedRole == UserRole.storeOwner &&
            _storeNameController.text.trim().isEmpty) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Store name is required')),
          );
          return;
        }
        if (_selectedRole == UserRole.storeOwner &&
            _storeAddressController.text.trim().isEmpty) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Store location is required')),
          );
          return;
        }
      }

      final liveLocation = context.read<LocationService>().currentLocation;
      final success = await auth.requestOtp(
        phone: _phoneController.text,
        email: _isSignUp ? _emailController.text : null,
        password: _isSignUp ? _passwordController.text : null,
        name: _nameController.text,
        role: _selectedRole,
        isSignUpFlow: _isSignUp,
        storeName: _isSignUp && _selectedRole == UserRole.storeOwner
            ? _storeNameController.text
            : null,
        storeAddress: _isSignUp && _selectedRole == UserRole.storeOwner
            ? _storeAddressController.text
            : null,
        storeLocation: _isSignUp && _selectedRole == UserRole.storeOwner
            ? liveLocation
            : null,
      );
      if (success && context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(auth.statusMessage ?? 'OTP sent')),
        );
      }
    } else {
      final success = await auth.verifyOtp(_otpController.text);
      if (!success && context.mounted) {
        final error = auth.errorMessage;
        if (error != null &&
            error.toLowerCase().contains(
              'already linked with another account',
            )) {
          showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Email already in use'),
              content: const Text(
                'This email is already associated with another account. Use a different email for signup, or sign in with that existing email.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }
        if (error == null) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Could not verify OTP')),
          );
        }
      }
    }
  }

  String _buttonLabel(AuthService auth) {
    if (!_isSignUp && auth.isPasswordLogin) return 'Sign In';
    if (_isSignUp) {
      return auth.otpRequested ? 'Verify and Create Account' : 'Send OTP';
    }
    return auth.otpRequested ? 'Verify and Continue' : 'Send OTP';
  }
}

class _AuthModeSwitch extends StatelessWidget {
  final bool isSignUp;
  final ValueChanged<bool> onChanged;

  const _AuthModeSwitch({required this.isSignUp, required this.onChanged});

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

  const _RoleGrid({required this.selectedRole, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final roles = <(UserRole, String, IconData, String)>[
      (
        UserRole.customer,
        'Customer',
        Icons.shopping_bag_outlined,
        'Personal shopping',
      ),
      (
        UserRole.storeOwner,
        'Store Owner',
        Icons.store_mall_directory_outlined,
        'Catalog and operations',
      ),
      (
        UserRole.delivery,
        'Delivery Agent',
        Icons.two_wheeler_outlined,
        'Trips and fulfillment',
      ),
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
            width: 160,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF211311) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? const Color(0xFF211311)
                    : const Color(0xFFE8DED5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  entry.$3,
                  color: selected ? Colors.white : AppTheme.primaryRed,
                ),
                const SizedBox(height: 14),
                Text(
                  entry.$2,
                  style: TextStyle(
                    color: selected ? Colors.white : AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.$4,
                  style: TextStyle(
                    color: selected ? Colors.white70 : AppTheme.textMedium,
                    fontSize: 11.5,
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
