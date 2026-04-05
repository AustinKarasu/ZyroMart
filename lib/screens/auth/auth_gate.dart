import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../customer/customer_main_screen.dart';
import '../delivery/delivery_main_screen.dart';
import '../store_owner/store_main_screen.dart';
import 'auth_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final user = auth.currentUser;
        if (user == null) {
          return const AuthScreen();
        }

        switch (user.role) {
          case UserRole.customer:
            return const CustomerMainScreen();
          case UserRole.storeOwner:
            return const StoreMainScreen();
          case UserRole.delivery:
            return const DeliveryMainScreen();
        }
      },
    );
  }
}
