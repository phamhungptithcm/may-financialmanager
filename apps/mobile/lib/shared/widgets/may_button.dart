/// Mây Family Finance — Shared Widget: MayButton (A03)
///
/// Primary/Secondary/Tertiary/Text variants with loading state,
/// disabled state, and double-submission guard.
/// All states visible and accessible.

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';
import 'package:may/shared/design_system/tokens/may_motion.dart';

/// Button variant controlling visual appearance.
enum MayButtonVariant {
  primary,     // Filled accent button (default CTA)
  secondary,   // Outlined button (secondary action)
  tertiary,    // Subtle filled button (group actions)
  text,        // Plain text link button
}

/// Reusable button widget with all required states.
class MayButton extends StatefulWidget {
  final String label;
  final MayButtonVariant variant;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? minWidth;
  final double? maxWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  const MayButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.minWidth,
    this.maxWidth,
    this.leadingIcon,
    this.trailingIcon,
  }) : variant = MayButtonVariant.primary;

  const MayButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.minWidth,
    this.maxWidth,
    this.leadingIcon,
    this.trailingIcon,
  }) : variant = MayButtonVariant.secondary;

  const MayButton.tertiary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.minWidth,
    this.maxWidth,
    this.leadingIcon,
    this.trailingIcon,
  }) : variant = MayButtonVariant.tertiary;

  const MayButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.minWidth,
    this.maxWidth,
    this.leadingIcon,
    this.trailingIcon,
  }) : variant = MayButtonVariant.text;

  @override
  State<MayButton> createState() => _MayButtonState();
}

class _MayButtonState extends State<MayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: MayMotion.tapDuration,
      vsync: this,
      lowerBound: 0.97,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: MayMotion.tapCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => setState(() => _pressed = true);
  void _onTapUp(TapUpDetails _) => setState(() => _pressed = false);
  void _onTapCancel() => setState(() => _pressed = false);

  void _safeOnPressed() {
    if (widget.onPressed != null && !widget.isLoading) {
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.isLoading;
    final isReducedMotion = MediaQuery.platformBrightnessOf(context) ==
        Brightness.dark; // Placeholder — read from mayTheme in Phase 1.

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale =
            (_pressed && !disabled) ? _scaleAnimation.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: disabled ? null : _safeOnPressed,
              borderRadius: BorderRadius.circular(16),
              splashFactory: NoSplash.splashFactory, // Custom splash handled below
              child: Container(
                constraints: BoxConstraints(
                  minWidth: widget.minWidth ?? (widget.variant == MayButtonVariant.text ? 0 : 120),
                  maxWidth: widget.maxWidth ?? double.infinity,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: _decoration(disabled: disabled),
                child: _content(context, isReducedMotion: isReducedMotion),
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _decoration({required bool disabled}) {
    switch (widget.variant) {
      case MayButtonVariant.primary:
        return BoxDecoration(
          color: disabled ? MayColors.disabled : MayColors.accent,
          borderRadius: BorderRadius.circular(16),
        );
      case MayButtonVariant.secondary:
        return BoxDecoration(
          color: disabled ? MayColors.surface : MayColors.canvas,
          border: Border.all(color: MayColors.accent, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        );
      case MayButtonVariant.tertiary:
        return BoxDecoration(
          color: disabled ? MayColors.surface : MayColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        );
      case MayButtonVariant.text:
        return const BoxDecoration();
    }
  }

  Widget _content(BuildContext context, {required bool isReducedMotion}) {
    final style = switch (widget.variant) {
      MayButtonVariant.primary => TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      MayButtonVariant.secondary => TextStyle(
          color: disabled() ? MayColors.disabled : MayColors.accent,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      MayButtonVariant.tertiary => TextStyle(
          color: disabled() ? MayColors.secondary : MayColors.accent,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      MayButtonVariant.text => TextStyle(
          color: disabled() ? MayColors.disabled : MayColors.accent,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
        ),
    };

    final hasContent = widget.label.isNotEmpty ||
        widget.leadingIcon != null ||
        widget.trailingIcon != null;

    if (!hasContent) return const SizedBox.shrink();

    final children = <Widget>[];

    if (widget.leadingIcon != null) {
      children.add(Icon(widget.leadingIcon!, size: 20, color: style.color));
      children.add(const SizedBox(width: 8));
    }

    children.add(Text(widget.label, style: style));

    if (widget.trailingIcon != null) {
      children.add(const SizedBox(width: 8));
      children.add(Icon(widget.trailingIcon!, size: 20, color: style.color));
    }

    if (widget.isLoading) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 12));
      children.add(_loadingIndicator(isReducedMotion: isReducedMotion));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  Widget _loadingIndicator({required bool isReducedMotion}) {
    if (isReducedMotion) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      );
    }
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
    );
  }

  bool disabled() {
    return widget.onPressed == null || widget.isLoading;
  }
}
