import 'package:flutter/material.dart';
import 'package:super_field/super_field.dart';

/// Renders `<@id|Label>` markup as a teal chip while editing and as bold
/// coloured text in read-only mode.
class MentionRule extends TokenRule {
  const MentionRule();

  @override
  String get id => 'mention';

  @override
  TokenMatcher get matcher => MarkupMatcher(tagPrefix: '@');

  @override
  TokenBehavior get behavior => TokenBehavior.atomic;

  @override
  InlineSpan buildSpan({
    required BuildContext context,
    required TokenMatch match,
    required TextStyle defaultStyle,
    required bool isReadOnly,
  }) {
    // match.groups = [id, label]
    final label = match.groups.length > 1 ? match.groups[1] : match.fullText;

    if (isReadOnly) {
      return TextSpan(
        text: '@$label',
        style: defaultStyle.copyWith(
          color: Colors.teal,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.teal.shade100.withAlpha(100),
          border: Border.all(color: Colors.teal.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('@'),
            Text(label),
          ],
        ),
      ),
    );
  }

  @override
  String toPlainText(TokenMatch match) {
    final label = match.groups.length > 1 ? match.groups[1] : match.fullText;
    return '@$label';
  }
}
