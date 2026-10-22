/// Mây Family Finance — Shared Widget: MayPrivacyAmount (A23)
///
/// Toggle-able amount redaction for public-facing display and lock-screen privacy.
/// Shows placeholder instead of financial value.

import 'package:flutter/material.dart';
import 'package:may/core/domain/money.dart';
import 'package:may/shared/design_system/tokens/may_typography.dart';

class MayPrivacyAmount extends StatefulWidget {
  final Money amount;
  final bool hidden;
  final String placeholder;
  final ValueChanged<bool>? onToggle;
  final TextStyle? textStyle;
  final IconData? hideIcon;
  final IconData? showIcon;

  const MayPrivacyAmount({
    super.key,
    required this.amount,
    this.hidden = false,
    this.placeholder = '•••',
    this.onToggle,
    this.textStyle,
    this.hideIcon = Icons.visibility_off,
    this.showIcon = Icons.visibility,
  });

  @override
  State<MayPrivacyAmount> createState() => _MayPrivacyAmountState();
}

class _MayPrivacyAmountState extends State<MayPrivacyAmount> {
  late bool _hidden;

  @override
  void initState() {
    super.initState();
    _hidden = widget.hidden;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() => _hidden = !_hidden);
        widget.onToggle?.call(_hidden);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _hidden ? widget.hideIcon : widget.showIcon,
            size: 18,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
          ),
          const SizedBox(width: 6),
          Text(
            _hidden ? widget.placeholder : widget.amount.format(),
            style: widget.textStyle ?? MayTypography.displayLarge(context),
          ),
        ],
      ),
    );
  }
}
