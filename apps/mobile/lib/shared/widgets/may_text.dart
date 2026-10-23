/// Mây Family Finance — Shared Widget: MayText (A01)
///
/// Thin wrapper around Text that applies MayTypography tokens,
/// handles overflow modes, and carries accessibility semantics.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Overflow handling mode for text content.
enum MayTextOverflow { ellipsis, fade, clip }

/// Semantic role for accessibility announcement.
enum MayTextRole { heading, body, caption, button, label, none }

/// Reusable text widget with Vietnamese diacritics support, dynamic type,
/// overflow handling, and semantics labels.
class MayText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final MayTextOverflow overflow;
  final MayTextRole role;
  final int? maxLines;
  final TextAlign? textAlign;
  final bool softWrap;
  final String? semanticsLabel;

  const MayText(
    this.data, {
    super.key,
    this.style,
    this.overflow = MayTextOverflow.ellipsis,
    this.role = MayTextRole.none,
    this.maxLines,
    this.textAlign,
    this.softWrap = true,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? Theme.of(context).textTheme.bodyLarge!;
    final overflowText = switch (overflow) {
      MayTextOverflow.ellipsis => TextOverflow.ellipsis,
      MayTextOverflow.fade => TextOverflow.fade,
      MayTextOverflow.clip => TextOverflow.clip,
    };

    Widget child = Text(
      data,
      style: effectiveStyle,
      overflow: maxLines != null ? overflowText : null,
      maxLines: maxLines,
      textAlign: textAlign,
      softWrap: softWrap,
      // Vietnamese diacritics are natively supported by SF Pro / Roboto.
    );

    if (semanticsLabel != null) {
      child = Semantics(
        label: semanticsLabel!,
        child: ExcludeSemantics(child: child),
      );
    } else if (role != MayTextRole.none) {
      // Add semantic role hint for screen readers.
      final semanticHint = switch (role) {
        MayTextRole.heading => 'Heading',
        MayTextRole.body => 'Body text',
        MayTextRole.caption => 'Caption',
        MayTextRole.button => 'Button',
        MayTextRole.label => 'Label',
        MayTextRole.none => null,
      };
      if (semanticHint != null) {
        child = Semantics(          child: child,
        );
      }
    }

    return child;
  }
}
