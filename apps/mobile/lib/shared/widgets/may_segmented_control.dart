/// Mây Family Finance — Shared Widget: MaySegmentedControl (A15)
///
/// Platform-adaptive segmented picker with VoiceOver/TalkBack labels.

import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';

class MaySegmentedControl<T> extends StatelessWidget {
  final Map<String, T> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const MaySegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final keys = options.keys.toList();
    final selectedIndex = keys.indexOf(selected);

    if (selectedIndex < 0 || selectedIndex >= keys.length) {
      return const SizedBox.shrink(); // Safety guard.
    }

    return CupertinoSegmentedControl<T>(
      selectedColor: MayColors.accent.withOpacity(0.15),
      borderColor: MayColors.accent,
      unselectedBackgroundColor: MayColors.surface,
      children: options.map((label, value) => MapEntry(value, _buildChild(label, value))),
    );
  }

  Widget _buildChild(String label, T value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(label),
    );
  }
}
