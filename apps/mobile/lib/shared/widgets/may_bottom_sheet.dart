/// Mây Family Finance — Shared Widget: MayBottomSheet (A09)
///
/// Modal bottom sheet with keyboard/safe-area awareness, title/body, and primary action.

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_typography.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';
import 'package:may/shared/design_system/tokens/may_spacing.dart';

class MayBottomSheet extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? primaryAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;
  final bool dismissible;
  final Color? barrierColor;

  const MayBottomSheet({
    super.key,
    required this.title,
    required this.body,
    this.primaryAction,
    this.secondaryLabel = 'Hủy',
    this.onSecondaryTap,
    this.dismissible = true,
    this.barrierColor,
  });

  /// Shows the bottom sheet modally.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget body,
    Widget? primaryAction,
    String? secondaryLabel,
    VoidCallback? onSecondaryTap,
    bool isScrollControlled = true,
    bool dismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      barrierColor:
          dismissible ? Colors.black.withOpacity(0.4) : Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => MayBottomSheet(
        title: title,
        body: body,
        primaryAction: primaryAction,
        secondaryLabel: secondaryLabel,
        onSecondaryTap: onSecondaryTap,
        dismissible: dismissible,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + MaySpacing.s16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title bar.
          Padding(
            padding: const EdgeInsets.all(MaySpacing.s20),
            child: Row(
              children: [
                Text(title, style: MayTypography.titleMedium(context)),
                const Spacer(),
                InkWell(
                  onTap: dismissible ? () => Navigator.of(context).pop() : null,
                  child:
                      Icon(Icons.close, size: 24, color: MayColors.secondary),
                ),
              ],
            ),
          ),

          // Divider.
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: MaySpacing.s16),

          // Body.
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: MaySpacing.s20),
              child: body),

          // Primary action.
          if (primaryAction != null) ...[
            const SizedBox(height: MaySpacing.s16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MaySpacing.s20),
              child: primaryAction!,
            ),
          ],

          // Secondary action.
          if (onSecondaryTap != null) ...[
            const SizedBox(height: MaySpacing.s8),
            Center(
              child: TextButton(
                onPressed: onSecondaryTap,
                child: Text(secondaryLabel ?? 'Hủy'),
              ),
            ),
          ],

          // Safe area.
          SafeArea(child: Container()),
        ],
      ),
    );
  }
}
