/// Mây Family Finance — Shared Widget: MayIconButton (A04)
///
/// Icon-only button with semantic label, min 48x48 hit area, and
/// solid/outlined/text variants matching the approved prototype.

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';

/// Button variant controlling visual appearance of an icon-only button.
enum IconButtonVariant {
  /// Filled circle background with icon colour (default).
  solid,

  /// Outlined circle with border only.
  outlined,

  /// No background or border; plain icon with label-like styling.
  text,
}

/// Reusable icon-only button with all required states (A04).
class MayIconButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final String? semanticLabel;
  final VoidCallback onPressed;
  final Color? iconColor;
  final Color? fillColor;
  final double? size;
  final IconButtonVariant variant;

  const MayIconButton({
    super.key,
    required this.icon,
    this.tooltip,
    required this.onPressed,
    this.semanticLabel,
    this.iconColor,
    this.fillColor,
    this.size = 24.0,
    this.variant = IconButtonVariant.outlined,
  });

  const MayIconButton.solid({
    super.key,
    required this.icon,
    this.tooltip,
    required this.onPressed,
    this.semanticLabel,
    this.iconColor,
    this.fillColor,
    this.size = 24.0,
  }) : variant = IconButtonVariant.solid;

  const MayIconButton.outlined({
    super.key,
    required this.icon,
    this.tooltip,
    required this.onPressed,
    this.semanticLabel,
    this.iconColor,
    this.fillColor,
    this.size = 24.0,
  }) : variant = IconButtonVariant.outlined;

  const MayIconButton.text({
    super.key,
    required this.icon,
    this.tooltip,
    required this.onPressed,
    this.semanticLabel,
    this.iconColor,
    this.fillColor,
    this.size = 24.0,
  }) : variant = IconButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor =
        iconColor ?? Theme.of(context).colorScheme.onSurface;
    final effectiveSize = size!;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: semanticLabel,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            decoration: _decoration(context, effectiveIconColor),
            child: Center(
              child: Icon(
                icon,
                size: effectiveSize,
                color: effectiveIconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration(BuildContext context, Color iconColor) {
    final theme = Theme.of(context);
    switch (variant) {
      case IconButtonVariant.solid:
        return BoxDecoration(
          color: fillColor ?? MayColors.accent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        );
      case IconButtonVariant.outlined:
        return BoxDecoration(
          border: Border.all(
              color:
                  fillColor ?? theme.dividerTheme.color ?? MayColors.divider),
          shape: BoxShape.circle,
        );
      case IconButtonVariant.text:
        return const BoxDecoration();
    }
  }
}
