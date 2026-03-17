import 'package:flutter/material.dart';
import 'package:super_field/super_field.dart';

/// Renders `#word` tokens as purple text.
class HashtagRule extends TokenRule {
  const HashtagRule();

  @override
  String get id => 'hashtag';

  @override
  TokenMatcher get matcher => RegexMatcher(RegExp(r'#[\w]+'));

  @override
  TokenBehavior get behavior => TokenBehavior.transparent;

  @override
  InlineSpan buildSpan({
    required BuildContext context,
    required TokenMatch match,
    required TextStyle defaultStyle,
    required bool isReadOnly,
  }) {
    return TextSpan(
      text: match.fullText,
      style: defaultStyle.copyWith(color: Colors.deepPurple),
    );
  }

  @override
  String toPlainText(TokenMatch match) => match.fullText;
}
