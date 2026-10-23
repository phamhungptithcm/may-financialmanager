/// Mây Family Finance — Environment Configuration
///
/// Supports dev / staging / prod environments.
/// No hardcoded secrets — configuration comes from:
/// - Build-time defines (flutter build --dart-define)
/// - Runtime secure storage (production keys only)
/// - Firebase default config (auto-loaded on iOS/Android)

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported deployment environments.
enum Environment { dev, staging, prod }

/// Configuration for the current environment.
class AppConfig {
  final Environment environment;
  final String appName;
  final bool emulatorMode;

  // -- Firebase config (injected at runtime) --
  // These are NOT hardcoded — populated from firebase_options.dart
  // or build-time dart-define values.
  final String? projectId;
  final String? appId;
  final String? apiKey;        // Not a secret per Firebase docs, but rules+auth required

  const AppConfig({
    required this.environment,
    required this.appName,
    this.emulatorMode = false,
    this.projectId,
    this.appId,
    this.apiKey,
  });

  bool get isDev => environment == Environment.dev;
  bool get isStaging => environment == Environment.staging;
  bool get isProd => environment == Environment.prod;

  /// Whether to connect to the Firebase emulator suite.
  bool get connectToEmulators => emulatorMode && isDev;

  // -- Feature flags (Phase 0 defaults) --
  bool get receiptCaptureEnabled => true;
  bool get investmentFeatures => false;  // Phase 3+
  bool get plusAvailable => true;

  @override
  String toString() => 'AppConfig($environment, emulator=$emulatorMode)';
}

/// Provider for the app configuration.
final appConfigProvider = Provider<AppConfig>((ref) {
  final envName = const String.fromEnvironment(
    'MAY_ENV',
    defaultValue: kDebugMode ? 'dev' : 'prod',
  );

  final emulatorMode = const bool.fromEnvironment(
    'MAY_EMULATOR',
    defaultValue: kDebugMode,
  );

  final env = Environment.values.firstWhere(
    (e) => e.name == envName,
    orElse: () => Environment.dev,
  );

  return AppConfig(
    environment: env,
    appName: 'Mây Family Finance',
    emulatorMode: emulatorMode,
    projectId: const String.fromEnvironment('MAY_PROJECT_ID'),
    appId: const String.fromEnvironment('MAY_APP_ID'),
    apiKey: const String.fromEnvironment('MAY_API_KEY'),
  );
});
