/// Mây Family Finance — Shared Widget: MayTextField (A11)
///
/// Text input with label, required indicator (*), validator, loading and disabled states.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';
import 'package:may/shared/design_system/tokens/may_typography.dart';

typedef MayValidator = String? Function(String? value);

class MayTextField extends StatefulWidget {
  final String? label;
  final bool required;
  final String? hintText;
  final TextStyle? textStyle;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextEditingController? controller;
  final ValueChanged<String>? onTextChanged;
  final MayValidator? validator;
  final int? maxLines;
  final bool enabled;
  final String? initialValue;

  const MayTextField({
    super.key,
    this.label,
    this.required = false,
    this.hintText,
    this.textStyle,
    this.keyboardType,
    this.inputFormatters,
    this.controller,
    this.onTextChanged,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.initialValue,
  });

  @override
  State<MayTextField> createState() => _MayTextFieldState();
}

class _MayTextFieldState extends State<MayTextField> {
  late final TextEditingController _internalController;
  late final TextEditingController _controller;
  String? _errorText;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _internalController = TextEditingController(text: widget.initialValue);
    _controller = widget.controller ?? _internalController;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  void _validate(String value) {
    if (widget.validator != null) {
      _errorText = widget.validator!(value.isEmpty ? null : value);
    } else {
      _errorText = null;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label with required indicator.
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: MayTypography.titleSmall(context).copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (widget.required) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: MayTypography.titleSmall(context).copyWith(
                    color: MayColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Input field.
        TextField(
          controller: _controller,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          enabled: widget.enabled,
          style: MayTypography.bodyLarge(context),
          decoration: InputDecoration(
            hintText: widget.hintText,
            filled: true,
            fillColor: _hasFocus ? theme.colorScheme.surface : MayColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _errorText != null
                    ? MayColors.danger
                    : _hasFocus
                        ? MayColors.accent
                        : MayColors.divider,
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: MayColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: MayColors.accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: MayColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: MayColors.danger, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            _validate(value);
            widget.onTextChanged?.call(value);
          },
          onTap: () => setState(() => _hasFocus = true),
          onTapOutside: (_) {},
        ),

        // Error text.
        if (_errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            _errorText!,
            style: MayTypography.labelSmall(context).copyWith(color: MayColors.danger),
          ),
        ],
      ],
    );
  }
}
