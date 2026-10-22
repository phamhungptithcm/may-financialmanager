/// Mây Family Finance — Shared Widget: MayErrorState (A21)
///
/// Error state with title, message, retry button, and optional correlation ID.

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';
import 'package:may/shared/design_system/tokens/may_typography.dart';
import 'package:may/shared/widgets/may_button.dart';

class MayErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  final String? correlationId;
  final bool showDetails;

  const MayErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.correlationId,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: MayColors.warning),
            const SizedBox(height: 16),

            Text(
              title,
              style: MayTypography.titleSmall(context).copyWith(
                color: MayColors.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              message,
              style: MayTypography.bodyMedium(context).copyWith(
                color: MayColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),

            // Optional correlation ID for support/debugging.
            if (showDetails && correlationId != null) ...[
              const SizedBox(height: 8),
              Text(
                'CorrID: $correlationId',
                style: MayTypography.labelSmall(context).copyWith(
                  color: MayColors.disabled,
                ),
              ),
            ],

            const SizedBox(height: 20),

            MayButton.primary(label: 'Thử lại', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
