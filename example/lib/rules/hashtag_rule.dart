import 'package:flutter/material.dart';
import 'package:super_field/super_field.dart';

/// Renders `#word` tokens as purple badge chips while editing and as coloured
/// bold text in read-only mode.
class HashtagRule extends TokenRule {
  const HashtagRule();

  @override
  String get id => 'hashtag';

  @override
  TokenMatcher get matcher => const StartsWithMatcher('#');

  @override
  TokenBehavior get behavior => TokenBehavior.atomic;

  @override
  InlineSpan buildSpan({
    required BuildContext context,
    required TokenMatch match,
    required TextStyle defaultStyle,
    required bool isReadOnly,
  }) {
    // match.fullText is e.g. "#flutter"
    if (isReadOnly) {
      return TextSpan(
        text: match.fullText,
        style: defaultStyle.copyWith(
          color: Colors.deepPurple,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Chip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          label: Text(match.fullText),
          backgroundColor: Colors.deepPurple.shade100,
          side: BorderSide(color: Colors.deepPurple.shade300),
          labelStyle: const TextStyle(fontSize: 12),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  @override
  String toPlainText(TokenMatch match) => match.fullText;
}
