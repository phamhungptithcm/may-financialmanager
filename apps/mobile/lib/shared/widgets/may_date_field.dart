/// Mây Family Finance — Shared Widget: MayDateField (A13)
///
/// Date picker field with Vietnamese locale formatting and timezone-aware
/// period picking (spec BR-06).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';
import 'package:may/shared/design_system/tokens/may_typography.dart';
import 'package:may/shared/models/local_date.dart';

/// Validator type for date fields.
typedef DateValidator = String? Function(LocalDate? value);

/// Reusable date picker field (A13).
class MayDateField extends StatefulWidget {
  final LocalDate? localDate;
  final String label;
  final bool required;
  final ValueChanged<LocalDate>? onChanged;
  final DateValidator? validator;
  final String? hintText;
  final String locale;

  const MayDateField({
    super.key,
    this.localDate,
    required this.label,
    this.required = false,
    this.onChanged,
    this.validator,
    this.hintText,
    this.locale = 'vi_VN',
  });

  @override
  State<MayDateField> createState() => _MayDateFieldState();
}

class _MayDateFieldState extends State<MayDateField> {
  late String _displayText;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _displayText = _formatDate(widget.localDate, widget.locale);
  }

  @override
  void didUpdateWidget(covariant MayDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localDate != widget.localDate) {
      _displayText = _formatDate(widget.localDate, widget.locale);
    }
    if (oldWidget.validator != widget.validator ||
        oldWidget.localDate != widget.localDate) {
      _validate();
    }
  }

  void _validate() {
    if (widget.validator != null) {
      _errorText = widget.validator!(widget.localDate);
    } else {
      _errorText = null;
    }
  }

  static String _formatDate(LocalDate? date, String locale) {
    if (date == null) return '';
    // Vietnamese formatting: "23 tháng 10, 2025"
    final monthNames = <String>[
      '',
      'tháng 1',
      'tháng 2',
      'tháng 3',
      'tháng 4',
      'tháng 5',
      'tháng 6',
      'tháng 7',
      'tháng 8',
      'tháng 9',
      'tháng 10',
      'tháng 11',
      'tháng 12',
    ];
    return '${date.day} tháng ${monthNames[date.month]}, ${date.year}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final effectiveLocale = widget.locale;
    int initialDay, initialMonth, initialYear;

    if (widget.localDate != null) {
      initialDay = widget.localDate!.day;
      initialMonth = widget.localDate!.month;
      initialYear = widget.localDate!.year;
    } else {
      final now = DateTime.now();
      initialDay = now.day;
      initialMonth = now.month;
      initialYear = now.year;
    }

    LocalDate? picked;

    if (Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS) {
      picked = await _showCupertinoDatePicker(
          context, initialYear, initialMonth, initialDay, effectiveLocale);
    } else {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime(initialYear, initialMonth, initialDay),
        firstDate: DateTime(1900, 1, 1),
        lastDate: DateTime(2100, 12, 31),
        locale: Locale.fromSubtags(
          languageCode: effectiveLocale.split('_').first,
          countryCode: effectiveLocale.contains('_')
              ? effectiveLocale.split('_').last
              : null,
        ),
      );
      if (pickedDate != null) {
        picked = LocalDate(pickedDate.year, pickedDate.month, pickedDate.day);
      }
    }

    final resultDate = picked;
    if (resultDate != null && mounted) {
      widget.onChanged?.call(resultDate);
    }
  }

  Future<LocalDate?> _showCupertinoDatePicker(
    BuildContext context,
    int initialYear,
    int initialMonth,
    int initialDay,
    String locale,
  ) async {
    final completer = Completer<LocalDate?>();
    DateTime pickerState = DateTime(initialYear, initialMonth, initialDay);

    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return Container(
          height: 220,
          padding: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(color: MayColors.secondary)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      completer.complete(LocalDate(pickerState.year,
                          pickerState.month, pickerState.day));
                      Navigator.of(ctx).pop();
                    },
                    child:
                        Text('Done', style: TextStyle(color: MayColors.accent)),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: pickerState,
                  onDateTimeChanged: (v) => setState(() => pickerState = v),
                  minimumDate: DateTime(1900, 1, 1),
                  maximumDate: DateTime(2100, 12, 31),
                ),
              ),
            ],
          ),
        );
      },
    );

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label.isNotEmpty) ...[
          Row(
            children: [
              Text(
                widget.label,
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
        GestureDetector(
          onTap: () => _pickDate(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: MayColors.inputFill,
              border: Border.all(
                color:
                    _errorText != null ? MayColors.danger : MayColors.divider,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _displayText.isNotEmpty
                        ? _displayText
                        : (widget.hintText ?? ''),
                    style: MayTypography.bodyLarge(context).copyWith(
                      color: _displayText.isEmpty ? MayColors.secondary : null,
                    ),
                  ),
                ),
                if (_displayText.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.calendar_today_outlined,
                      size: 20, color: MayColors.secondary),
                ],
              ],
            ),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 4),
          Text(_errorText!,
              style: MayTypography.labelSmall(context)
                  .copyWith(color: MayColors.danger)),
        ],
      ],
    );
  }
}
