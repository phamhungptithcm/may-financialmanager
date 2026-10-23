/// Mây Family Finance — Design Token: MayRadius
///
/// Source: `docs/specs/02_UI_UX.md` card radius `16–20`.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

abstract final class MayRadius {
  const MayRadius._();

  /// 4 dp — subtle rounding for chips and badges.
  static const double s4 = 4.0;

  /// 8 dp — standard chip / tag rounding.
  static const double s8 = 8.0;

  /// 12 dp — elevated card minor radius.
  static const double s12 = 12.0;

  /// 16 dp — standard card radius (spec minimum).
  static const double s16 = 16.0;

  /// 20 dp — hero card / modal radius (spec maximum).
  static const double s20 = 20.0;

  // -- Material RADIUS helpers --

  /// Circular radius for full-circle elements.
  static const circular = BorderRadius.zero;

  /// Rounded corner for buttons and small cards.
  static RoundedRectangleBorder button() =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(s12));

  /// Rounded corner for standard cards.
  static RoundedRectangleBorder card() =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(s16));

  /// Rounded corner for hero / modal cards.
  static RoundedRectangleBorder heroCard() =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(s20));

  /// Fully rounded pill shape.
  static RoundedRectangleBorder pill(double height) => RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(height / 2),
          topRight: Radius.circular(height / 2),
          bottomLeft: Radius.circular(height / 2),
          bottomRight: Radius.circular(height / 2),
        ),
      );
}
