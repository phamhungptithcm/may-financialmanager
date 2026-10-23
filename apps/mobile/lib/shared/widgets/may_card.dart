/// Mây Family Finance — Shared Widget: MayCard (A05)
///
/// Grouping card with consistent radius (16–20 dp), elevation, and optional
/// tap behaviour.

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_spacing.dart';
import 'package:may/shared/design_system/tokens/may_elevation.dart';
import 'package:may/shared/design_system/tokens/may_motion.dart';
import 'package:may/shared/design_system/tokens/may_radius.dart';

/// Visual variant for MayCard.
enum MayCardVariant { flat, elevated, hero }

class MayCard extends StatefulWidget {
  final Widget child;
  final MayCardVariant variant;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const MayCard({
    super.key,
    required this.child,
    this.variant = MayCardVariant.elevated,
    this.margin,
    this.onTap,
    this.backgroundColor,
  });

  @override
  State<MayCard> createState() => _MayCardState();

  // -- Convenience constructors --

  factory MayCard.elevated(
      {Key? key,
      required Widget child,
      VoidCallback? onTap,
      EdgeInsetsGeometry? margin}) {
    return MayCard(
        key: key,
        child: child,
        variant: MayCardVariant.elevated,
        onTap: onTap,
        margin: margin);
  }

  factory MayCard.flat(
      {Key? key,
      required Widget child,
      VoidCallback? onTap,
      EdgeInsetsGeometry? margin}) {
    return MayCard(
        key: key,
        child: child,
        variant: MayCardVariant.flat,
        onTap: onTap,
        margin: margin);
  }

  factory MayCard.hero(
      {Key? key,
      required Widget child,
      VoidCallback? onTap,
      EdgeInsetsGeometry? margin}) {
    return MayCard(
        key: key,
        child: child,
        variant: MayCardVariant.hero,
        onTap: onTap,
        margin: margin);
  }
}

class _MayCardState extends State<MayCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: MayMotion.tapDuration,
      vsync: this,
      lowerBound: 0.995,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elevation = switch (widget.variant) {
      MayCardVariant.flat => MayElevation.none,
      MayCardVariant.elevated => MayElevation.level2,
      MayCardVariant.hero => MayElevation.level3,
    };

    final radius = switch (widget.variant) {
      MayCardVariant.flat => MayRadius.s12,
      MayCardVariant.elevated => MayRadius.s16,
      MayCardVariant.hero => MayRadius.s20,
    };

    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale,
          child: Material(
            color: widget.backgroundColor ?? Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(radius),
            elevation: elevation.elevation,
            shadowColor: elevation.shadowColor,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(radius),
              child: Padding(
                  padding:
                      widget.margin ?? const EdgeInsets.all(MaySpacing.s16),
                  child: child!),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }

  void _onPanDown(DragDownDetails _) => setState(() {
        _hoverController.forward();
        _scale = 0.995;
      });
  void _onPanUp(DragEndDetails _) => setState(() {
        _hoverController.reverse();
        _scale = 1.0;
      });
  void _onPanCancel() => setState(() {
        _hoverController.reverse();
        _scale = 1.0;
      });
}
