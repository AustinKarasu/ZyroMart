import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/admin/admin_auth_gate.dart';
import 'services/admin_auth_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseService.initialize();
  } catch (error) {
    debugPrint('Supabase init skipped: $error');
  }
  runApp(const ZyroMartAdminApp());
}

class ZyroMartAdminApp extends StatelessWidget {
  const ZyroMartAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminAuthService()..initialize(),
      child: MaterialApp(
        title: 'ZyroMart Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AdminAuthGate(),
      ),
    );
  }
}
