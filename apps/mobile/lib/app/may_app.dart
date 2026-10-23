/// Mây Family Finance — Application Bootstrap
///
/// Entry point that assembles the app shell with:
/// - Theme (light/dark)
/// - Router (go_router)
/// - Localization (vi-VN default, en-US secondary)
/// - Provider scope (Riverpod)
/// - Accessibility settings (reduced motion, large text)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:may/app/config/environment.dart';
import 'package:may/core/localization/app_localizations.dart';

/// The top-level MyApp widget.
///
/// Phase 0 scaffold — full auth + onboarding integration in Phase 1.
class MayApp extends ConsumerWidget {
  const MayApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    // -- System UI (dark bar on light canvas) --
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      // Theme — platform adaptive (Cupertino on iOS, Material on Android)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: _preferredTheme(config),
      // Localization — vi-VN default per spec
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('vi', 'VN'),
      // Router — go_router integration in Phase 1
      home: Scaffold(
        body: Center(child: const Text('Mây Family Finance')),
      ),
    );
  }

  /// Determines which theme to use. Phase 0 defaults to light mode.
  ThemeMode _preferredTheme(AppConfig config) {
    return ThemeMode
        .system; // Will read OS preference; user override in Phase 1.
  }
}
