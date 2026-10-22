/// Mây Family Finance — Design Token: MayTypography
///
/// Source: `docs/specs/02_UI_UX.md` typography section.
/// Display 30–34, title 24–28, section 18–20, body 15–17, caption 12–13.
/// All styles honour [MediaQuery.textScalerOf] for dynamic type scaling.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

/// Semantic typography tokens matching the approved prototype.
///
/// Uses SF Pro on iOS (system default) and platform system font on Android.
/// No custom font family is required — this project relies on native
/// typography to respect OS preferences.
abstract final class MayTypography {
  const MayTypography._();

  // -- Display / hero text (30–34 dp) --

  /// Hero number display for balances, net worth figures.
  static TextStyle displayLarge(BuildContext context, {Color? color}) {
    final base = const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      package: 'may',
    );
    return _applyScaler(base, context).copyWith(color: color);
  }

  /// Large display for onboarding screens / landing headers.
  static TextStyle displayMedium(BuildContext context, {Color? color}) {
    final base = const TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      package: 'may',
    );
    return _applyScaler(base, context).copyWith(color: color);
  }

  // -- Title text (24–28 dp) --

  /// Section heading / hero card title.
  static TextStyle titleLarge(BuildContext context, {Color? color}) {
    final base = const TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      package: 'may',
    );
    return _applyScaler(base, context).copyWith(color: color);
  }

  /// Screen title / navigation bar text.
  static TextStyle titleMedium(BuildContext context, {Color? color}) {
    final base = const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      package: 'may',
    );
    return _applyScaler(base, context).copyWith(color: color);
  }

  /// Card heading / group title.
  static TextStyle titleSmall(BuildContext context, {Color? color}) {
    final base = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      package: 'may',
    );
    return _applyScaler(base, context).copyWith(color: color);
  }

  // -- Body text (15–17 dp) --

  /// Primary body text for paragraphs and descriptions.
  static TextStyle bodyLarge(BuildContext context, {Color? color}) {
    final base = const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      package: 'may',
    );
    return _applyScaler(base, context).copyWith(color: color);
  }

  /// Standard body text for form labels and list titles.
  static TextStyle bodyMedium(BuildContext context, {Color? color}) {
    final base = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      package: 'may',
    );
    return _applyScaler(base, context).copyWith(color: color);
  }

  /// Compact body for secondary information.
  static TextStyle bodySmall(BuildContext context, {Color? color}) {
    final base = const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      package: 'may',
    );
    return _applyScaler(base, context).copyWith(color: color);
  }

  // -- Label / caption text (12–13 dp) --

  /// Caption for dates, timestamps, and small annotations.
  static TextStyle labelSmall(BuildContext context, {Color? color}) {
    final base = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      package: 'may',
    );
    return _applyScaler(base, context).copyWith(color: color);
  }

  /// Overline / badge label text.
  static TextStyle labelOverline(BuildContext context, {Color? color}) {
    final base = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.8,
      package: 'may',
    );
    return _applyScaler(base, context).copyWith(color: color);
  }

  // -- Money-specific styling --

  /// Tabular-nums enabled style for aligned number columns (lists, tables).
  static TextStyle moneyTabular(BuildContext context, {Color? color}) {
    final base = bodyLarge(context);
    return base.copyWith(
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  // -- Helper --

  /// Applies the current media query text scaler to a base style.
  static TextStyle _applyScaler(TextStyle base, BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return base.copyWith(fontSize: base.fontSize! * scaler.scale(1));
  }

  // -- Vietnamese diacritics note --
  // The platform font (SF Pro / Roboto) includes full Vietnamese support.
  // No custom font is required unless a brand font is approved later.
}
