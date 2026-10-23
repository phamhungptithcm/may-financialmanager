/// Mây Family Finance — Shared Widget: MaySearchField (A14)
///
/// Search input with optional debouncing and clear button.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';
import 'package:may/shared/design_system/tokens/may_typography.dart';

/// Reusable debounced search field (A14).
class MaySearchField extends StatefulWidget {
  final String? query;
  final ValueChanged<String>? onChanged;
  final bool debounce;
  final int debounceMs;
  final String hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final ValueChanged<void>? onClear;

  const MaySearchField({
    super.key,
    this.query,
    this.onChanged,
    this.debounce = true,
    this.debounceMs = 300,
    this.hintText = 'Tim kiem',
    this.prefixIcon,
    this.suffixIcon,
    this.onClear,
  });

  @override
  State<MaySearchField> createState() => _MaySearchFieldState();
}

class _MaySearchFieldState extends State<MaySearchField> {
  late final TextEditingController _controller;
  String? _currentQuery;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.query ?? '';
    _controller = TextEditingController(text: _currentQuery);
  }

  @override
  void didUpdateWidget(covariant MaySearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query &&
        _controller.text != (widget.query ?? '')) {
      if (widget.query != _currentQuery) {
        _controller.text = widget.query ?? '';
        _currentQuery = widget.query;
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    _currentQuery = '';
    if (widget.debounce) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(
        Duration(milliseconds: widget.debounceMs),
        () => widget.onChanged?.call(''),
      );
    } else {
      widget.onChanged?.call('');
    }
    if (widget.onClear != null) widget.onClear!(null);
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _currentQuery != null && _currentQuery!.isNotEmpty;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: MayColors.inputFill,
        border: Border.all(color: MayColors.divider),
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: TextField(
        controller: _controller,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: MayTypography.bodySmall(context)
              .copyWith(color: MayColors.secondary),
          prefixIcon:
              Icon(Icons.search_outlined, size: 20, color: MayColors.secondary),
          suffixIcon: hasQuery
              ? GestureDetector(
                  onTap: _clear,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: MayColors.secondary),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
        style: MayTypography.bodyMedium(context),
      ),
    );
  }
}
