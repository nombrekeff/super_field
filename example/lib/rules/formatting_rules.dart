import 'package:flutter/material.dart';
import 'package:super_field/super_field.dart';

/// Renders `**text**` as bold text using [SurroundedByMatcher].
class BoldRule extends TokenRule {
  const BoldRule();

  @override
  String get id => 'bold';

  @override
  TokenMatcher get matcher =>
      const SurroundedByMatcher(prefix: '**', suffix: '**');

  @override
  // Transparent so the cursor can navigate inside the token normally.
  TokenBehavior get behavior => TokenBehavior.transparent;

  @override
  InlineSpan buildSpan({
    required BuildContext context,
    required TokenMatch match,
    required TextStyle defaultStyle,
    required bool isReadOnly,
  }) {
    // match.groups[0] is the content between the ** delimiters.
    final content = match.groups.isNotEmpty ? match.groups[0] : match.fullText;
    return TextSpan(
      text: isReadOnly ? content : match.fullText,
      style: defaultStyle.copyWith(fontWeight: FontWeight.bold),
    );
  }

  @override
  String toPlainText(TokenMatch match) =>
      match.groups.isNotEmpty ? match.groups[0] : match.fullText;
}

/// Renders `_text_` as italic text using [SurroundedByMatcher].
class ItalicRule extends TokenRule {
  const ItalicRule();

  @override
  String get id => 'italic';

  @override
  TokenMatcher get matcher =>
      const SurroundedByMatcher(prefix: '_', suffix: '_');

  @override
  TokenBehavior get behavior => TokenBehavior.transparent;

  @override
  InlineSpan buildSpan({
    required BuildContext context,
    required TokenMatch match,
    required TextStyle defaultStyle,
    required bool isReadOnly,
  }) {
    final content = match.groups.isNotEmpty ? match.groups[0] : match.fullText;
    return TextSpan(
      text: isReadOnly ? content : match.fullText,
      style: defaultStyle.copyWith(fontStyle: FontStyle.italic),
    );
  }

  @override
  String toPlainText(TokenMatch match) =>
      match.groups.isNotEmpty ? match.groups[0] : match.fullText;
}
