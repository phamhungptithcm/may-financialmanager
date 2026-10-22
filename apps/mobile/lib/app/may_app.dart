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
import 'package:intl/package.dart' as intl;
import 'package:may/app/router.dart';
import 'package:may/app/config/environment.dart';
import 'package:may/core/localization/app_localizations.dart';
import 'package:may/shared/design_system/tokens/may_theme.dart';

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
        systemNavigationBarColor: MayTheme.canvas,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      // Theme — platform adaptive (Cupertino on iOS, Material on Android)
      theme: MayTheme.light(),
      darkTheme: MayTheme.dark(),
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
      // Router
      routerConfig: MayRouter(initialAuthState: AuthState.pending).router,
    );
  }

  /// Determines which theme to use. Phase 0 defaults to light mode.
  ThemeMode _preferredTheme(AppConfig config) {
    return ThemeMode.system; // Will read OS preference; user override in Phase 1.
  }
}
