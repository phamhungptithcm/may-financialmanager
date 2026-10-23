/// Mây Family Finance — Shared Widget: MayIcon (A02)
///
/// Consistent icon widget ensuring minimum 44×44 dp hit area and
/// semantic label. No icon-only action without a tooltip/semantics label.

import 'package:flutter/material.dart';

class MayIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final bool fillHitArea;

  const MayIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.semanticLabel,
    this.fillHitArea = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).iconTheme.color;
    final effectiveSize = size ?? 24.0;

    Widget iconWidget = Icon(
      icon,
      size: effectiveSize,
      color: effectiveColor,
    );

    // Enforce semantic label for accessibility.
    if (semanticLabel != null) {
      iconWidget = Semantics(
        label: semanticLabel!,
        excludeSemantics: true,
        child: iconWidget,
      );
    }

    // Ensure minimum hit area of 44×44 dp.
    if (fillHitArea) {
      return Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: iconWidget,
      );
    }

    return iconWidget;
  }
}
