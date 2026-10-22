/// Mây Family Finance — Shared Widget: MayConfirmDialog (A10)
///
/// Confirmation dialog with explicit destructive label and semantic safety.

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';
import 'package:may/shared/design_system/tokens/may_typography.dart';
import 'package:may/shared/widgets/may_button.dart';

enum MayConfirmType { info, warning, destructive }

class MayConfirmDialog extends StatelessWidget {
  final String title;
  final String description;
  final MayConfirmType confirmType;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const MayConfirmDialog({
    super.key,
    required this.title,
    required this.description,
    this.confirmType = MayConfirmType.info,
    this.confirmLabel,
    this.cancelLabel = 'Hủy',
    required this.onConfirm,
    this.onCancel,
  });

  /// Shows the confirmation dialog modally.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String description,
    MayConfirmType confirmType = MayConfirmType.info,
    String? confirmLabel,
    String cancelLabel = 'Hủy',
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => MayConfirmDialog(
        title: title,
        description: description,
        confirmType: confirmType,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionColor = switch (confirmType) {
      MayConfirmType.info => MayColors.accent,
      MayConfirmType.warning => MayColors.warning,
      MayConfirmType.destructive => MayColors.danger,
    };

    return AlertDialog(
      title: Text(title, style: MayTypography.titleMedium(context)),
      content: Text(description, style: MayTypography.bodyMedium(context)),
      actions: [
        // Cancel button.
        MayButton.text(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),

        const SizedBox(width: 8),

        // Confirm button with type-specific colour.
        MayButton.primary(
          label: confirmLabel ?? 'Xác nhận',
          onPressed: onConfirm,
        ),
      ],
    );
  }
}
