/// Mây Family Finance — Design Token: MayTheme
///
/// Unified theme provider merging light and dark variants.
/// All app widgets read colours, typography, spacing through this token.

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';

/// App-wide theme token extension.
extension MayThemeExtension on BuildContext {
  MayThemeData get mayTheme => MayTheme.of(this);
}

/// Theme data combining all design tokens for a single theme variant.
class MayThemeData {
  final MayColors colors;
  final Brightness brightness;

  const MayThemeData({required this.colors, required this.brightness});

  bool get isDark => brightness == Brightness.dark;

  /// Default canvas background colour.
  Color get canvas => isDark ? MayColors.canvasDark : MayColors.canvas;

  /// Default surface fill colour (cards, sheets).
  Color get surface => isDark ? MayColors.surfaceDark : MayColors.surface;

  /// Primary text colour.
  Color get primaryText => isDark ? MayColors.primaryDark : MayColors.primary;

  /// Secondary text colour.
  Color get secondaryText =>
      isDark ? MayColors.secondaryDark : MayColors.secondary;

  /// Accent colour (CTAs, links, positive actions).
  Color get accent => isDark ? MayColors.accentDark : MayColors.accent;

  /// Success colour.
  Color get success => isDark ? MayColors.successDark : MayColors.success;

  /// Warning colour.
  Color get warning => isDark ? MayColors.warningDark : MayColors.warning;

  /// Danger / error colour.
  Color get danger => isDark ? MayColors.dangerDark : MayColors.danger;

  /// Default scaffold background.
  Color get scaffoldBackground => canvas;

  /// Card surface with elevation (computed from [surface]).
  Color get cardSurface => surface;

  /// Text colour for dark backgrounds.
  Color get onCanvas => primaryText;

  /// Text colour on [surface].
  Color get onSurface => primaryText;

  /// Text colour on [accent].
  Color get onAccent => const Color(0xFFFFFFFF);
}

/// Theme builder for light mode (approved prototype palette).
ThemeData MayTheme.light() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    // Canvas & surface colours.
    scaffoldBackgroundColor: MayColors.canvas,
    cardColor: MayColors.surface,
    dividerColor: MayColors.divider,

    // Colour scheme from prototype palette.
    colorScheme: ColorScheme.fromSeed(
      seedColor: MayColors.accent,
      primary: MayColors.primary,
      secondary: MayColors.secondary,
      surface: MayColors.surface,
      onSurface: MayColors.primary,
      error: MayColors.danger,
      onError: MayColors.surface,
      brightness: Brightness.light,
    ),

    // Typography — uses system font (SF Pro on iOS, Roboto on Android).
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
      labelSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),

    // Button themes.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MayColors.accent,
        foregroundColor: MayColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    // Input decoration.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MayColors.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: MayColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: MayColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: MayColors.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    // List tile theme.
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: EdgeInsets.zero,
    ),
  );
}

/// Theme builder for dark mode (approximate inverse of light).
ThemeData MayTheme.dark() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: MayColors.canvasDark,
    cardColor: MayColors.surfaceDark,
    dividerColor: const Color(0xFF3A3F3C),

    colorScheme: ColorScheme.fromSeed(
      seedColor: MayColors.accentDark,
      primary: MayColors.primaryDark,
      secondary: MayColors.secondaryDark,
      surface: MayColors.surfaceDark,
      onSurface: MayColors.primaryDark,
      error: MayColors.dangerDark,
      onError: MayColors.surfaceDark,
      brightness: Brightness.dark,
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
      labelSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MayColors.accentDark,
        foregroundColor: MayColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2F2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3A3F3C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: MayColors.accentDark, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: MayColors.dangerDark),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    listTileTheme: const ListTileThemeData(
      shape: RoundedRectangleBorder(),
      contentPadding: EdgeInsets.zero,
    ),
  );
}

/// Provides [MayThemeData] from the current [BuildContext].
extension MayTheme on BuildContext {
  MayThemeData of(BuildContext context) {
    final theme = Theme.of(context);
    return MayThemeData(
      colors: MayColors(),
      brightness: theme.brightness,
    );
  }
}
