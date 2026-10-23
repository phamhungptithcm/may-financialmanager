import 'package:flutter/material.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';

/// Platform-adaptive segmented picker with VoiceOver/TalkBack labels.
class MaySegmentedControl<T extends Object> extends StatefulWidget {
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const MaySegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<MaySegmentedControl<T>> createState() => _MaySegmentedControlState<T>();
}

class _MaySegmentedControlState<T extends Object>
    extends State<MaySegmentedControl<T>> {
  late T _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  void didUpdateWidget(MaySegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selected != widget.selected) {
      _selected = widget.selected;
    }
  }

  List<ButtonSegment<T>> _buildSegments() {
    return widget.options.entries.map((entry) {
      return ButtonSegment<T>(
        value: entry.key,
        label: Text(entry.value),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Segmented control',
      child: SegmentedButton<T>(
        segments: _buildSegments(),
        selected: <T>{_selected},
        onSelectionChanged: (newSelection) {
          if (newSelection.isNotEmpty && newSelection.first != _selected) {
            setState(() => _selected = newSelection.first);
            widget.onChanged(_selected);
          }
        },
        style: SegmentedButton.styleFrom(
          selectedForegroundColor: MayColors.surface,
          selectedBackgroundColor: MayColors.accent,
          backgroundColor: MayColors.surface,
        ),
      ),
    );
  }
}
