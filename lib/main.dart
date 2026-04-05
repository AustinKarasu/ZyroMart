import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/catalog_service.dart';
import 'services/location_service.dart';
import 'services/order_service.dart';
import 'services/supabase_service.dart';
import 'screens/auth/animated_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        ChangeNotifierProvider(create: (_) => AuthService()..initialize()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => CatalogService()..load()),
        ChangeNotifierProvider(create: (_) => LocationService()..initialize()),
        ChangeNotifierProxyProvider<AuthService, OrderService>(
          create: (_) => OrderService(),
          update: (_, auth, orderService) => orderService!..bindUser(auth.currentUser),
        ),
      ],
      child: MaterialApp(
        title: 'ZyroMart',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AnimatedSplashScreen(),
      ),
    );
  }
}
