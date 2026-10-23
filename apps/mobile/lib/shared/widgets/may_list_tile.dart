/// Mây Family Finance — Shared Widget: MayListTile (A08)
///
/// Consistent list item with title, subtitle, leading/trailing widgets, and tap target.

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';
import 'package:may/shared/design_system/tokens/may_radius.dart';

import 'package:may/shared/design_system/tokens/may_typography.dart';
import 'package:may/shared/design_system/tokens/may_spacing.dart';

class MayListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? contentPadding;

  const MayListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.backgroundColor,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MayRadius.s8),
      child: Padding(
        padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: MaySpacing.s20, vertical: MaySpacing.s12),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: trailing != null ? MaySpacing.s16 : MaySpacing.s12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: MayTypography.bodyLarge(context)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: MayTypography.bodySmall(context).copyWith(color: MayColors.secondary)),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: MaySpacing.s16),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
