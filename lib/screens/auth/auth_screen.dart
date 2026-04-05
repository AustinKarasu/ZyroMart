import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nameController = TextEditingController(text: 'Aayan Karasu');
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  UserRole _selectedRole = UserRole.customer;

  @override
  void initState() {
    super.initState();
    _emailController.text = 'customer@zyromart.com';
    _phoneController.text = '+919876543220';
  }

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

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8F1212), Color(0xFFDA3B35), Color(0xFFFFB15B)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 28,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.flash_on, color: Colors.white, size: 34),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Phone-verified quick commerce across customer, store, and delivery.',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        auth.canUseSupabaseAuth
                            ? 'Phone OTP is connected to Supabase. Use a real mobile number with country code.'
                            : 'Supabase SMS OTP is not configured yet. Use demo OTP 123456 to explore all three apps.',
                        style: const TextStyle(
                          color: AppTheme.textMedium,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _RoleSelector(
                        selectedRole: _selectedRole,
                        onChanged: (role) {
                          setState(() {
                            _selectedRole = role;
                            _emailController.text = _defaultEmailForRole(role);
                            _phoneController.text = _defaultPhoneForRole(role);
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
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
                        decoration: const InputDecoration(
                          labelText: 'Email Address (Optional)',
                          prefixIcon: Icon(Icons.alternate_email),
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
                        const SizedBox(height: 8),
                        Text(
                          auth.errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.primaryRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
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
                                    if (success && mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            auth.canUseSupabaseAuth
                                                ? 'OTP sent to ${_phoneController.text.trim()}'
                                                : 'Demo OTP ready. Enter 123456.',
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    final success = await auth.verifyOtp(_otpController.text);
                                    if (!success && mounted && auth.errorMessage == null) {
                                      messenger.showSnackBar(
                                        const SnackBar(content: Text('Could not verify OTP')),
                                      );
                                    }
                                  }
                                },
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                )
                              : Text(auth.otpRequested ? 'Verify and Continue' : 'Send OTP'),
                        ),
                      ),
                    ],
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

class _RoleSelector extends StatelessWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;

  const _RoleSelector({
    required this.selectedRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final roles = <(UserRole, String, IconData, String)>[
      (UserRole.customer, 'Customer', Icons.shopping_bag_outlined, 'Shop the storefront'),
      (UserRole.storeOwner, 'Store Owner', Icons.storefront_outlined, 'Run catalog and orders'),
      (UserRole.delivery, 'Delivery', Icons.delivery_dining_outlined, 'Complete last-mile trips'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: roles.map((entry) {
        final isSelected = entry.$1 == selectedRole;
        return InkWell(
          onTap: () => onChanged(entry.$1),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 145,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryRed : const Color(0xFFF8F5F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(entry.$3, color: isSelected ? Colors.white : AppTheme.primaryRed),
                const SizedBox(height: 10),
                Text(
                  entry.$2,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.$4,
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : AppTheme.textMedium,
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
