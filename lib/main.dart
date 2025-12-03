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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  StreamSubscription? _linkSubscription;
  late AppLinks _appLinks;

  // Theme & Locale state
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _handleInitialLink();
    _handleIncomingLinks();
    _loadAppSettings();
  }

  void _handleInitialLink() async {
    // Handle link if app was opened from a link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _processLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }
  }

  void _handleIncomingLinks() {
    // Handle links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      _processLink(uri);
    }, onError: (err) {
      debugPrint('Error handling incoming link: $err');
    });
  }

  void _processLink(Uri uri) {
    // Extract invitation code from URL
    // Supports: https://alzcare.app/invite?code=XXXXX
    if (uri.host == 'alzcare.app' && uri.path == '/invite') {
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        // Navigate to invitation acceptance screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.pushNamed(
            AppRoutes.invitationAcceptance,
            arguments: code,
          );
        });
      }
    } else if (uri.scheme == 'alzcare') {
      // Handle custom scheme: alzcare://invite?code=XXXXX
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.pushNamed(
            AppRoutes.invitationAcceptance,
            arguments: code,
          );
        });
      }
    }
  }

  // -------- App settings: theme & language --------
  Future<void> _loadAppSettings() async {
    try {
      // Generic theme (used before login or when no user-specific setting)
      final themeString = SharedPrefsHelper.getString('themeMode');
      switch (themeString) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
        case null:
        default:
          _themeMode = ThemeMode.system;
      }

      // Generic language
      final langCode = SharedPrefsHelper.getString('languageCode');
      if (langCode != null && langCode.isNotEmpty) {
        _locale = Locale(langCode);
      } else {
        _locale = const Locale('en');
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading app settings: $e');
    }
  }

  /// تحميل إعدادات مستخدم معيّن (لكل دور / يوزر)
  Future<void> loadUserSettings({
    required String role, // 'doctor' | 'patient' | 'family'
    required String userId,
  }) async {
    try {
      final themeKey = 'themeMode_${role}_$userId';
      final langKey = 'languageCode_${role}_$userId';

      final userTheme = SharedPrefsHelper.getString(themeKey);
      final userLang = SharedPrefsHelper.getString(langKey);

      if (userTheme != null || userLang != null) {
        setState(() {
          if (userTheme != null) {
            switch (userTheme) {
              case 'light':
                _themeMode = ThemeMode.light;
                break;
              case 'dark':
                _themeMode = ThemeMode.dark;
                break;
              case 'system':
              default:
                _themeMode = ThemeMode.system;
            }
          }
          if (userLang != null && userLang.isNotEmpty) {
            _locale = Locale(userLang);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user settings: $e');
    }
  }

  /// Call this from anywhere (via context.findAncestorStateOfType) to change theme
  Future<void> setThemeMode(
    ThemeMode mode, {
    String? role,
    String? userId,
  }) async {
    setState(() {
      _themeMode = mode;
    });
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    // لو فيه يوزر محدد، خزّنه له هو؛ وإلا خزّنه كإعداد عام
    if (role != null && userId != null) {
      await SharedPrefsHelper.saveString(
        'themeMode_${role}_$userId',
        value,
      );
    } else {
      await SharedPrefsHelper.saveString('themeMode', value);
    }
  }

  /// Call this to change app language (e.g. Locale('ar') or Locale('en'))
  Future<void> setLocale(
    Locale locale, {
    String? role,
    String? userId,
  }) async {
    setState(() {
      _locale = locale;
    });

    if (role != null && userId != null) {
      await SharedPrefsHelper.saveString(
        'languageCode_${role}_$userId',
        locale.languageCode,
      );
    } else {
      await SharedPrefsHelper.saveString(
        'languageCode',
        locale.languageCode,
      );
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenSizer(
      size: const Size(430, 932),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: AppRoutes.roleSelection,
        onGenerateRoute: AppRouter.onGenerate,
        // home: Builder(builder: (context) => DoctorSelectionScreen(),),
        supportedLocales: const [Locale("en"), Locale("ar")],
        locale: _locale,
        themeMode: _themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
      ),
    );
  }
}

