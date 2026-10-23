/// Mây Family Finance — Shared Widget: MaySectionHeader (A06)
///
/// Short section title with optional "See all" / action link.

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';
import 'package:may/shared/design_system/tokens/may_spacing.dart';
import 'package:may/shared/design_system/tokens/may_typography.dart';

/// Reusable section header row (A06).
class MaySectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const MaySectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MaySpacing.s16),
      child: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: MayTypography.titleSmall(context).copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: MaySpacing.s8),
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: MayTypography.bodySmall(context).copyWith(
                  color: MayColors.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
