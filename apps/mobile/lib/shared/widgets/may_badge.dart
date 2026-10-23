/// Mây Family Finance — Shared Widget: MayBadge (A17)
///
/// Numeric or status badge with colour and text state.

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';
import 'package:may/shared/design_system/tokens/may_typography.dart';

enum MayBadgeKind { default_, info, success, warning, alert }

class MayBadge extends StatelessWidget {
  final String label;
  final MayBadgeKind kind;
  final double? maxWidth;

  const MayBadge({
    super.key,
    required this.label,
    this.kind = MayBadgeKind.default_,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = switch (kind) {
      MayBadgeKind.default_ => (MayColors.accent, MayColors.surface),
      MayBadgeKind.info => (
          MayColors.accent.withOpacity(0.15),
          MayColors.accent
        ),
      MayBadgeKind.success => (
          MayColors.success.withOpacity(0.15),
          MayColors.success
        ),
      MayBadgeKind.warning => (
          MayColors.warning.withOpacity(0.15),
          MayColors.warning
        ),
      MayBadgeKind.alert => (
          MayColors.danger.withOpacity(0.15),
          MayColors.danger
        ),
    };

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: MayTypography.labelSmall(context).copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
