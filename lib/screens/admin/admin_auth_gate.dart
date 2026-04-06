import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/admin_auth_service.dart';
import '../../services/admin_service.dart';
import 'admin_dashboard_screen.dart';
import 'admin_sign_in_screen.dart';

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminAuthService>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated || !auth.isAdmin) {
          return const AdminSignInScreen();
        }

        return ChangeNotifierProvider(
          create: (_) {
            final service = AdminService();
            service.loadDashboard();
            return service;
          },
          child: const AdminDashboardScreen(),
        );
      },
    );
  }
}
