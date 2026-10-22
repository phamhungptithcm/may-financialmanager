/// Mây Family Finance — Design Token: MayMotion
///
/// Source: `docs/specs/02_UI_UX.md` motion section.
/// All durations honour `MediaQuery.reduceMotionEnabled`.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

abstract final class MayMotion {
  const MayMotion._();

  // -- Durations (ms) --

  /// Tap / quick feedback transition: 120–160 ms.
  static const Duration tapDuration = Duration(milliseconds: 140);

  /// Sheet presentation: 280–320 ms.
  static const Duration sheetDuration = Duration(milliseconds: 300);

  /// Page / route transition: 220–260 ms.
  static const Duration pageDuration = Duration(milliseconds: 240);

  /// Reorder spring: ~240 ms with overshoot.
  static const Duration reorderDuration = Duration(milliseconds: 240);

  /// Skeleton shimmer cycle (non-essential, disabled under reduced motion).
  static const Duration shimmerCycle = Duration(milliseconds: 1500);

  /// Toast / snackbar display time.
  static const Duration toastDuration = Duration(seconds: 3);

  // -- Curves --

  /// Standard ease-out curve for most transitions.
  static const Curve tapCurve = Curves.easeOutCubic;

  /// Spring-like curve for sheet presentation.
  static const Curve sheetCurve = Curves.easeOutCubic;

  /// Page transition with slight overshoot feel.
  static const Curve pageCurve = Curves.easeInOutCubic;

  /// Reorder spring with bounce.
  static const Curve reorderCurve = Curves.easeOutBack;

  /// Subtle fade-in for content reveal.
  static const Curve fadeInCurve = Curves.easeIn;

  // -- Reduced motion support --

  /// Returns the appropriate duration given the user's reduce-motion setting.
  static Duration adapt(Duration original, {bool reducedMotion = false}) =>
      reducedMotion ? original * 3 : original;

  /// Returns the appropriate curve given the user's reduce-motion setting.
  static Curve adaptCurve(Curve original, {bool reducedMotion = false}) =>
      reducedMotion ? Curves.linear : original;

  /// Checks if a [Duration] would be considered "essential" motion that
  /// cannot be disabled without harming usability feedback.
  static bool isEssential(Duration d) => d.inMilliseconds <= 200;
}
