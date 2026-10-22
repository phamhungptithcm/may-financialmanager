/// Mây Family Finance — Shared Widget: MayFilterChip (A16)
///
/// Multi-select chip with selected/normal states and accessible toggle.

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';
import 'package:may/shared/design_system/tokens/may_typography.dart';

class MayFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onToggle;
  final IconData? icon;

  const MayFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onToggle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onToggle(!selected),
      borderRadius: BorderRadius.circular(MayRadius.s12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? MayColors.accent.withOpacity(0.15) : MayColors.surface,
          border: Border.all(
            color: selected ? MayColors.accent : MayColors.divider,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(MayRadius.s12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, size: 16, color: selected ? MayColors.accent : MayColors.secondary),
            if (icon != null && label.isNotEmpty) const SizedBox(width: 4),
            Text(
              label,
              style: MayTypography.labelSmall(context).copyWith(
                color: selected ? MayColors.accent : MayColors.secondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
