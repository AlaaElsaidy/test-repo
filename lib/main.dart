import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'config/Theme/app_theme.dart';
import 'config/injector/app_injector.dart';
import 'config/router/router.dart';
import 'config/router/routes.dart';
import 'config/screen_sizer/ScreenSizer.dart';
import 'core/shared-prefrences/shared-prefrences-helper.dart';
import 'core/supabase/supabase-config.dart';
import 'core/di/injection_container.dart';
import 'core/repositories/tracking_repository.dart';
import 'core/tests/debug_location_upload.dart';
import 'l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Injector.inject();
  } catch (e) {
    debugPrint('Error initializing Injector: $e');
  }
  
  try {
    await SupabaseConfig.initialize();
    // تهيئة DI بعد Supabase
    setupDependencies();
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
  }
  
  try {
    await SharedPrefsHelper.init();
  } catch (e) {
    debugPrint('Error initializing SharedPreferences: $e');
  }
  
  try {
    Stripe.publishableKey =
        "pk_test_51SFtogRwYUVxFXZjh0dBu1dHGA2Gg3oXgZydNu5xgs26UNNJEsajZjAc8eAX2NLBtZLNTArMcuBUZL553AMJOO6c00V4sPebuf";
    await Stripe.instance.applySettings();
  } catch (e) {
    debugPrint('Error initializing Stripe: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      // 🔴 TEMPORARY: استخدام أداة Debug لتشخيص مشكلة الموقع
      home: DebugLocationUploadScreen(
        trackingRepository: getIt<TrackingRepository>(),
      ),
      supportedLocales: const [Locale("en"), Locale("ar")],
      locale: const Locale("en"),
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
    );
  }
}

