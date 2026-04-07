import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/app_telemetry_service.dart';
import 'services/auth_service.dart';
import 'services/app_preferences_service.dart';
import 'services/cart_service.dart';
import 'services/biometric_service.dart';
import 'services/catalog_service.dart';
import 'services/location_service.dart';
import 'services/order_service.dart';
import 'services/supabase_service.dart';
import 'screens/auth/animated_splash_screen.dart';
import 'screens/shared/backend_unavailable_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppTelemetryService.logCrash(
      error: details.exception,
      stackTrace: details.stack,
      appVariant: 'storefront',
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppTelemetryService.logCrash(
      error: error,
      stackTrace: stack,
      appVariant: 'storefront',
      source: 'platform_dispatcher',
    );
    return false;
  };
  try {
    await SupabaseService.initialize();
    await AppTelemetryService.flush();
    await AppTelemetryService.trackFeatureUse(
      eventName: 'app_launch',
      appVariant: 'storefront',
    );
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }
  runApp(const ZyroMartApp());
}

class ZyroMartApp extends StatelessWidget {
  const ZyroMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppPreferencesService()..initialize(),
        ),
        ChangeNotifierProxyProvider<AppPreferencesService, AuthService>(
          create: (_) => AuthService(),
          update: (_, preferences, auth) =>
              auth!..applyPreferences(preferences),
        ),
        ChangeNotifierProxyProvider<AuthService, CartService>(
          create: (_) => CartService(),
          update: (_, auth, cart) => cart!..bindUser(auth.currentUser),
        ),
        ChangeNotifierProvider(create: (_) => CatalogService()..load()),
        ChangeNotifierProvider(create: (_) => LocationService()..initialize()),
        Provider(create: (_) => BiometricService()),
        ChangeNotifierProxyProvider<AuthService, OrderService>(
          create: (_) => OrderService(),
          update: (_, auth, orderService) => orderService!..bindUser(auth.currentUser),
        ),
      ],
      child: Consumer<AppPreferencesService>(
        builder: (context, preferences, _) => MaterialApp(
          title: 'ZyroMart',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          darkTheme: AppTheme.darkTheme,
          themeMode: preferences.themeMode,
          home: SupabaseService.isInitialized
              ? const AnimatedSplashScreen()
              : BackendUnavailableScreen(
                  appTitle: 'ZyroMart',
                  message: SupabaseService.backendStatusMessage,
                ),
        ),
      ),
    );
  }
}


