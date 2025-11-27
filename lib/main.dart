import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

Future<void> _initializeEnv() async {
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Env file missing or unreadable: $e');
    // Ensure dotenv is marked as initialized even if file is missing
    if (!dotenv.isInitialized) {
      dotenv.testLoad(fileInput: '');
    }
  }

  const defaults = {
    'TIMEZONE': 'Africa/Cairo',
    'STT_PROVIDER': 'device',
    'TTS_PROVIDER': 'azure',
    'GROQ_MODEL': 'llama-3.1-8b-instant', // النموذج المتاح حالياً من Groq
    'AZURE_TTS_REGION': 'eastus',
    // Azure TTS uses: https://{region}.tts.speech.microsoft.com/cognitiveservices/v1
    // Custom endpoint can be set here if needed
    // 'AZURE_TTS_ENDPOINT': 'https://eastus.api.cognitive.microsoft.com/cognitiveservices/v1',
    // NOTE: API keys should be set in .env file, not here!
    // 'GROQ_API_KEY': 'your-key-here',
    // 'AZURE_TTS_API_KEY': 'your-key-here',
  };

  defaults.forEach((key, value) {
    dotenv.env.putIfAbsent(key, () => value);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeEnv();

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
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _linkSubscription;
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _handleInitialLink();
    _handleIncomingLinks();
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
        locale: const Locale("en"),
        themeMode: ThemeMode.system,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
      ),
    );
  }
}

