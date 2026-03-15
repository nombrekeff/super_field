import 'package:flutter/material.dart';
import 'package:super_field/super_field.dart';

/// Detects URLs (http / https) in the text using [RegexMatcher] and renders
/// them as underlined blue hyperlink-style text.
class UrlRule extends TokenRule {
  const UrlRule();

  @override
  String get id => 'url';

  @override
  TokenMatcher get matcher => RegexMatcher(
        RegExp(
          r'https?://[^\s]+',
          caseSensitive: false,
        ),
      );

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
      style: defaultStyle.copyWith(
        color: Colors.blue.shade700,
        decoration: TextDecoration.underline,
      ),
    );
  }
}
