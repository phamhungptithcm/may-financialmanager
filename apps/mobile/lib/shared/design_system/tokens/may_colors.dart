/// Mây Family Finance — Design Token: MayColors
///
/// Source: `docs/FamilyClanMockupFullFlow.html` CSS variables and
/// `docs/specs/02_UI_UX.md` design tokens section.
/// These are STARTER values — validate contrast AA in dark mode before
/// promoting to production use.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

/// Semantic colour tokens derived from the approved prototype palette.
///
/// Light mode colours (default):
/// - canvas  : #F7F8F6  (off-white background)
/// - surface : #FFFFFF  (card/surface fill)
/// - primary : #171A19  (dominant text, headings)
/// - secondary: #68726E  (supporting text, descriptions)
/// - accent   : #187A60  (CTAs, links, positive indicators)
/// - success  : #218761  (confirmed/safe state)
/// - warning  : #BC7E2C  (attention required)
/// - danger   : #C65050  (error, destructive actions)
///
/// All values support light and dark themes. Dark-mode overrides are
/// applied via [MayColors.dark] or [MayTheme.dark].
abstract final class MayColors {
  // -- Semantic colours (light mode) --

  static const canvas = Color(0xFFF7F8F6);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF171A19);
  static const secondary = Color(0xFF68726E);
  static const accent = Color(0xFF187A60);
  static const success = Color(0xFF218761);
  static const warning = Color(0xFFBC7E2C);
  static const danger = Color(0xFFC65050);

  // -- Derived / state colours (light mode) --

  /// Colour for disabled / inactive states.
  static const disabled = Color(0xFFB0B8B4);

  /// Overlay / backdrop colour for modals and sheets.
  static const overlay = Color(0x99000000);

  /// Skeleton / shimmer base colour.
  static const skeletonBase = Color(0xFFE8EBE9);

  /// Skeleton / shimmer highlight colour.
  static const skeletonHighlight = Color(0xFFF2F3F1);

  // -- Light-only dividers and borders --

  /// Border line between content sections.
  static const divider = Color(0xFFE4E7E5);

  /// Subtle background for input fields.
  static const inputFill = Color(0xFFFDFDFD);

  // -- State-aware wrappers (Material 3 compatible) --

  /// Returns a [WidgetStateProperty] resolving to [accent] in all states.
  static WidgetStateProperty<Color?> accentColor() => WidgetStatePropertyAll(accent);

  /// Returns a [WidgetStateProperty] resolving to [danger] when pressed,
  /// [disabled] when disabled, [primary] otherwise.
  static WidgetStateProperty<Color?> primaryColor({Color? light}) => _PrimaryColorState(light ?? primary);

  // -- Dark-mode overrides (approximate WCAG AA-safe) --
  // TODO: validate against prototype dark CSS after FigJam export review.

  static const canvasDark = Color(0xFF1A1D1C);
  static const surfaceDark = Color(0xFF242826);
  static const primaryDark = Color(0xFFF0F2EF);
  static const secondaryDark = Color(0xFFA5ADAA);
  static const accentDark = Color(0xFF3DA87D);
  static const successDark = Color(0xFF48C97E);
  static const warningDark = Color(0xFFECB844);
  static const dangerDark = Color(0xFFE27B7B);
}

class _PrimaryColorState extends WidgetStateProperty<Color?> {
  final Color defaultColor;
  _PrimaryColorState(this.defaultColor);

  @override
  Color? resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return MayColors.disabled;
    if (states.contains(WidgetState.pressed)) return MayColors.secondary;
    return defaultColor;
  }
}
