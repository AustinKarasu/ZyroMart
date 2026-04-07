import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/admin/admin_auth_gate.dart';
import 'screens/shared/backend_unavailable_screen.dart';
import 'services/app_telemetry_service.dart';
import 'services/admin_auth_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppTelemetryService.logCrash(
      error: details.exception,
      stackTrace: details.stack,
      appVariant: 'admin',
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppTelemetryService.logCrash(
      error: error,
      stackTrace: stack,
      appVariant: 'admin',
      source: 'platform_dispatcher',
    );
    return false;
  };
  try {
    await SupabaseService.initialize();
    await AppTelemetryService.flush();
    await AppTelemetryService.trackFeatureUse(
      eventName: 'app_launch',
      appVariant: 'admin',
    );
  } catch (error) {
    debugPrint('Supabase init failed: $error');
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
        home: SupabaseService.isInitialized
            ? const AdminAuthGate()
            : BackendUnavailableScreen(
                appTitle: 'ZyroMart Admin',
                message: SupabaseService.backendStatusMessage,
                accentColor: const Color(0xFF163250),
              ),
      ),
    );
  }
}


