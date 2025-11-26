import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'config/Theme/app_theme.dart';
import 'config/Theme/theme-cubit/ThemeCubit.dart';
import 'config/injector/app_injector.dart';
import 'config/screen_sizer/ScreenSizer.dart';
import 'core/lang-cubit/lang_cubit.dart';
import 'core/shared-prefrences/shared-prefrences-helper.dart';
import 'core/supabase/supabase-config.dart';
import 'l10n/app_localizations.dart';
import 'screens/doctor/doctor_main_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Injector.inject();
  await SupabaseConfig.initialize();
  await SharedPrefsHelper.init();
  Stripe.publishableKey =
      "pk_test_51SFtogRwYUVxFXZjh0dBu1dHGA2Gg3oXgZydNu5xgs26UNNJEsajZjAc8eAX2NLBtZLNTArMcuBUZL553AMJOO6c00V4sPebuf";
  await Stripe.instance.applySettings();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenSizer(
      size: const Size(430, 932),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()..loadTheme()),
          BlocProvider(create: (_) => LanguageCubit()..loadLanguage()),
        ],
        child: BlocBuilder<LanguageCubit, Locale>(
          builder: (context, locale) {
            return BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return MaterialApp(
                  navigatorKey: navigatorKey,
                  debugShowCheckedModeBanner: false,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  // initialRoute: AppRoutes.login,
                  // onGenerateRoute: AppRouter.onGenerate,
                  home: const DoctorMainScreen(),
                  supportedLocales: const [Locale("en"), Locale("ar")],
                  locale: locale,
                  themeMode: themeMode,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                );
              },
            );
          },
        ),
      ),
    );
  }
}


