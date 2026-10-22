/// Mây Family Finance — Design Token: MaySpacing
///
/// Source: `docs/specs/02_UI_UX.md` spacing tokens `4, 8, 12, 16, 20, 24, 32`.
/// All values are in logical density units (dp).

// ignore_for_file: public_member_api_docs

abstract final class MaySpacing {
  const MaySpacing._();

  /// 2 dp — minimal spacing for compact items.
  static const double s2 = 2.0;

  /// 4 dp — minimum spacing unit.
  static const double s4 = 4.0;

  /// 8 dp — twice the base unit.
  static const double s8 = 8.0;

  /// 12 dp — compact grouping.
  static const double s12 = 12.0;

  /// 16 dp — standard card padding / element gap.
  static const double s16 = 16.0;

  /// 20 dp — content horizontal padding (from spec).
  static const double s20 = 20.0;

  /// 24 dp — section-level spacing.
  static const double s24 = 24.0;

  /// 32 dp — major section separation.
  static const double s32 = 32.0;

  /// 48 dp — page-level margins.
  static const double s48 = 48.0;

  /// 64 dp — full-page vertical spacing.
  static const double s64 = 64.0;

  /// 80 dp — hero / landing content padding.
  static const double s80 = 80.0;

  // -- Computed convenience constants --

  /// Default horizontal padding for screen content (~20 dp).
  static const double pagePadding = s20;

  /// Default gap between child widgets in a column layout.
  static const double verticalGap = s16;

  /// Minimum gap for list items.
  static const double listItemGap = s4;
}
