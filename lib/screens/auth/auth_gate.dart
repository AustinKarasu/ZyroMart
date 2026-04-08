import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../services/app_preferences_service.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../customer/customer_main_screen.dart';
import '../delivery/delivery_main_screen.dart';
import '../store_owner/store_main_screen.dart';
import 'onboarding_auth_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (!auth.authReady) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = auth.currentUser;
        if (user == null) {
          return const OnboardingAuthScreen();
        }

        final destination = switch (user.role) {
          UserRole.customer => const CustomerMainScreen(),
          UserRole.storeOwner => const StoreMainScreen(),
          UserRole.delivery => const DeliveryMainScreen(),
        };

        final preferences = context.watch<AppPreferencesService>();
        if (preferences.biometricUnlock &&
            auth.shouldPromptBiometricAfterLogin) {
          return _BiometricGate(
            child: destination,
            onUnlocked: () => auth.markBiometricPromptCompleted(),
          );
        }

        return destination;
      },
    );
  }
}

class _BiometricGate extends StatefulWidget {
  final Widget child;
  final VoidCallback onUnlocked;

  const _BiometricGate({required this.child, required this.onUnlocked});

  @override
  State<_BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<_BiometricGate> {
  bool _unlocked = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy || _unlocked) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final success = await BiometricService.authenticate(
      reason: 'Authenticate to continue into your ZyroMart account',
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _unlocked = success;
      if (!success) {
        _error = 'Biometric verification was not completed. Try again to continue.';
      }
    });
    if (success) {
      widget.onUnlocked();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) {
      return widget.child;
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fingerprint, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Unlock ZyroMart',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Biometric unlock is enabled for this device.',
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _unlock,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Authenticate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
