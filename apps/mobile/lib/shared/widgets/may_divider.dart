/// Mây Family Finance — Shared Widget: MayDivider (A07)
///
/// Token-consistent horizontal separator respecting spacing tokens.

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';

class MayDivider extends StatelessWidget {
  final double indent;
  final double endIndent;
  final double thickness;
  final Color? color;

  const MayDivider({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.thickness = 1,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: thickness,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: color ?? MayColors.divider,
    );
  }
}
