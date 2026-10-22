/// Mây Family Finance — Shared Widget: MaySkeleton (A19)
///
/// Loading placeholder without continuous animation when reduced motion is enabled.

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';
import 'package:may/shared/design_system/tokens/may_motion.dart';

class MaySkeleton extends StatefulWidget {
  final MaySkeletonShape shape;
  final Size? size;
  final Color? color;
  final double borderRadius;

  const MaySkeleton({
    super.key,
    this.shape = MaySkeletonShape.rect,
    this.size,
    this.color,
    this.borderRadius = 8,
  });

  @override
  State<MaySkeleton> createState() => _MaySkeletonState();
}

enum MaySkeletonShape { rect, circle, pill }

class _MaySkeletonState extends State<MaySkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final reducedMotion = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    _controller = AnimationController(
      duration: MayMotion.shimmerCycle,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? MayColors.skeletonBase;
    final highlightColor = widget.color != null
        ? widget.color!.withOpacity(0.8)
        : MayColors.skeletonHighlight;

    // Under reduced motion, show a static placeholder with no shimmer.
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final color = Color.lerp(baseColor, highlightColor, _animation.value)!;
        return _buildShape(color);
      },
    );
  }

  Widget _buildShape(Color color) {
    switch (widget.shape) {
      case MaySkeletonShape.rect:
        return Container(
          width: widget.size?.width,
          height: widget.size?.height ?? 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      case MaySkeletonShape.circle:
        final diameter = widget.size?.width ?? widget.size?.height ?? 40;
        return Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      case MaySkeletonShape.pill:
        final height = widget.size?.height ?? 24;
        return Container(
          width: widget.size?.width ?? 80,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        );
    }
  }
}
