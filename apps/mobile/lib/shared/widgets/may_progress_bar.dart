/// Mây Family Finance — Shared Widget: MayProgressBar (A18)
///
/// Linear progress indicator for budgets with overrun visual when used > limit.

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';
import 'package:may/shared/design_system/tokens/may_typography.dart';

class MayProgressBar extends StatelessWidget {
  final int used; // minor units (integer)
  final int target; // minor units (integer)
  final bool allowOverLimit;
  final String? label;

  const MayProgressBar({
    super.key,
    required this.used,
    required this.target,
    this.allowOverLimit = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (target <= 0) return const _EmptyBar();

    final percent = (used / target * 100).clamp(allowOverLimit ? 0 : 0, 100.0);
    final isOverLimit = used > target;
    final isNearLimit = !isOverLimit && percent >= 80;

    final color = isOverLimit
        ? MayColors.danger
        : isNearLimit
            ? MayColors.warning
            : MayColors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label or percentage.
        if (label != null) ...[
          Text(label!, style: MayTypography.labelSmall(context)),
          const SizedBox(height: 4),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: MayTypography.labelSmall(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],

        // Bar track.
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            backgroundColor: MayColors.skeletonBase,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),

        // Overrun detail.
        if (isOverLimit && allowOverLimit) ...[
          const SizedBox(height: 4),
          Text(
            'Vượt $used - target $target',
            style: MayTypography.labelSmall(context)
                .copyWith(color: MayColors.danger),
          ),
        ],
      ],
    );
  }
}

class _EmptyBar extends StatelessWidget {
  const _EmptyBar();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(height: 8, color: MayColors.skeletonBase),
    );
  }
}
