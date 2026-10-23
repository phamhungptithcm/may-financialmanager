/// Mây Family Finance — Shared Widget: MayToast (A22)
///
/// Lightweight toast/snackbar with severity levels. Accessible announcement.

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';
import 'package:may/shared/design_system/tokens/may_radius.dart';

import 'package:may/shared/design_system/tokens/may_motion.dart';

enum MayToastSeverity { info, success, warning, error }

class MayToast {
  /// Shows a snackbar with [message] and [severity].
  static Future<void> show(
    BuildContext context, {
    required String message,
    MayToastSeverity severity = MayToastSeverity.info,
    Duration duration = MayMotion.toastDuration,
  }) async {
    final bgColor = switch (severity) {
      MayToastSeverity.info => MayColors.accent,
      MayToastSeverity.success => MayColors.success,
      MayToastSeverity.warning => MayColors.warning,
      MayToastSeverity.error => MayColors.danger,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: bgColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MayRadius.s8)),
        // Accessibility: announces message via TalkBack/VoiceOver.
      ),
    );
    return;
  }
}
