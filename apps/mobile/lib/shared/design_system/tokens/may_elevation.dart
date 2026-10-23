/// Mây Family Finance — Design Token: MayElevation
///
/// 4 elevation levels matching Material depth semantics without copying
/// Apple assets. Designed for both light and dark themes.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_radius.dart';

abstract final class MayElevation {
  const MayElevation._();

  /// Level 1 — subtle card on canvas (0.5 dp equivalent).
  static final level1 = _MayElevation(
    elevation: 0.5,
    shadowColor: Color(0x0A171A19),
    shape: MayRadius.card(),
  );

  /// Level 2 — standard card (1 dp equivalent).
  static final level2 = _MayElevation(
    elevation: 1.0,
    shadowColor: Color(0x14171A19),
    shape: MayRadius.card(),
  );

  /// Level 3 — elevated / floating card (2 dp equivalent).
  static final level3 = _MayElevation(
    elevation: 2.0,
    shadowColor: Color(0x1F171A19),
    shape: MayRadius.heroCard(),
  );

  /// Level 4 — sheet / modal overlay (6 dp equivalent).
  static final level4 = _MayElevation(
    elevation: 6.0,
    shadowColor: Color(0x33171A19),
    shape: MayRadius.heroCard(),
  );

  /// No elevation — flat surface.
  static final none = _MayElevation(elevation: 0);
}

class _MayElevation {
  final double elevation;
  final Color shadowColor;
  final RoundedRectangleBorder? shape;

  const _MayElevation({
    required this.elevation,
    this.shadowColor = const Color(0x00000000),
    this.shape,
  });

  RoundedRectangleBorder? borderRadius() {
    if (shape == null) return null;
    return RoundedRectangleBorder(
      borderRadius: shape!.borderRadius,
    );
  }
  double get elevationValue => elevation;
}


