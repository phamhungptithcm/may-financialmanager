/// Mây Family Finance — Shared Widget: MayMoneyField (A12)
///
/// Numeric input for integer minor units (no float).
/// Displays formatted currency string; collects raw minor unit on submit.
/// Invariant: NEVER accept floating-point money from user input.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:may/core/domain/money.dart';
import 'package:may/shared/widgets/may_text_field.dart';

class MayMoneyField extends StatefulWidget {
  final Money? value;
  final String currency;
  final ValueChanged<Money?> onChanged;
  final String? label;
  final bool required;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextStyle? textStyle;

  const MayMoneyField({
    super.key,
    this.value,
    this.currency = 'VND',
    required this.onChanged,
    this.label,
    this.required = false,
    this.hintText,
    this.keyboardType,
    this.textStyle,
  });

  @override
  State<MayMoneyField> createState() => _MayMoneyFieldState();
}

class _MayMoneyFieldState extends State<MayMoneyField> {
  late final TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value != null ? _formatForInput(widget.value!.minor) : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Format number with thousand separators for input display.
  String _formatForInput(int minor) {
    final negative = minor < 0;
    final absMinor = minor.abs();
    return '${negative ? '-' : }${absMinor.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    )}';
  }

  void _onChanged(String raw) {
    // Remove commas and parse as integer minor units.
    final cleaned = raw.replaceAll(',', '');
    int? parsed;
    if (cleaned.isEmpty || cleaned == '-') {
      parsed = null;
    } else {
      parsed = int.tryParse(cleaned);
    }

    if (parsed == null) {
      widget.onChanged(null);
      return;
    }

    // Prevent overflow for safe integer range.
    if (parsed.abs() > 9_007_199_254_740_991) return; // near MAX_SAFE_INTEGER

    final money = parsed == 0 ? null : Money(minor: parsed, currency: widget.currency);
    widget.onChanged(money);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);

    return MayTextField(
      label: widget.label,
      required: widget.required,
      controller: _controller,
      hintText: widget.hintText ?? '0',
      keyboardType: TextInputType.numberWithOptions(significant: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,15}')), // 15 digit max
        NumericInputFormatter(),
      ],
      textStyle: widget.textStyle ?? MayTypography.moneyTabular(context),
      onTextChanged: _onChanged,
    );
  }
}

/// Custom input formatter that adds thousand separators as user types.
class NumericInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Only allow digits and optional leading minus.
    if (!RegExp(r'^-?\d*$').hasMatch(newValue.text)) {
      return oldValue;
    }

    var text = newValue.text;
    if (text.isEmpty) {
      return newValue.copyWith(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final negative = text.startsWith('-');
    var digits = negative ? text.substring(1) : text;
    int cursorOffset = newValue.selection.extentOffset - (negative ? 1 : 0);

    // Add thousand separators.
    String formatted;
    if (digits.length <= 3) {
      formatted = digits;
    } else {
      formatted = digits.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }

    final newText = negative ? '-$formatted' : formatted;
    final newOffset = cursorOffset.clamp(0, newText.length);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
