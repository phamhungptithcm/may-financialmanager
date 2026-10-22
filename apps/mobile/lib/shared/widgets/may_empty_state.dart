/// Mây Family Finance — Shared Widget: MayEmptyState (A20)
///
/// Actionable empty state with title, description, and optional action button.

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';
import 'package:may/shared/design_system/tokens/may_typography.dart';

class MayEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final Widget? action;
  final IconData? icon;
  final Color? iconColor;

  const MayEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.action,
    this.icon,
    this.iconColor = MayColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Optional icon.
            if (icon != null) ...[
              Icon(icon, size: 56, color: iconColor.withOpacity(0.5)),
              const SizedBox(height: 16),
            ],

            // Title.
            Text(
              title,
              style: MayTypography.titleSmall(context).copyWith(
                color: MayColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description.
            Text(
              description,
              style: MayTypography.bodyMedium(context).copyWith(
                color: MayColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),

            // Action button (if provided).
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
