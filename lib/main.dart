import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/order_service.dart';
import 'services/supabase_service.dart';
import 'screens/role_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Supabase if credentials are configured.
  // Falls back to mock data if not available.
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase init skipped: $e');
  }
  runApp(const ZyroMartApp());
}

class ZyroMartApp extends StatelessWidget {
  const ZyroMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
      ],
      child: MaterialApp(
        title: 'ZyroMart',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const RoleSelectionScreen(),
      ),
    );
  }
}
