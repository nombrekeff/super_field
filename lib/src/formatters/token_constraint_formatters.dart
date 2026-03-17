import 'package:flutter/services.dart';

import '../lexer/token_match.dart';
import '../lexer/token_rule.dart';
import 'token_input_formatter.dart';

/// Allows only a single token from [ruleId].
///
/// Empty input is always accepted. In-progress entry is accepted when any of
/// the target rule's [TokenRule.inputMatchers] report a partial match.
class SingleTokenOnlyFormatter extends TokenInputFormatter {
  const SingleTokenOnlyFormatter({
    required super.lexer,
    required this.ruleId,
  });

  final String ruleId;

  @override
  TextEditingValue formatAst(
    TextEditingValue oldValue,
    TextEditingValue newValue,
    List<TokenMatch> ast,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final rule = _ruleFor(ruleId);
    if (rule == null) return oldValue;

    if (_isAllowedPartial(rule, text)) return newValue;

    if (ast.length != 1) return oldValue;

    final token = ast.first;
    if (token.ruleId != ruleId) return oldValue;
    if (token.start != 0 || token.end != text.length) return oldValue;

    return newValue;
  }

  TokenRule? _ruleFor(String id) {
    for (final rule in lexer.rules) {
      if (rule.id == id) return rule;
    }
    return null;
  }

  bool _isAllowedPartial(TokenRule rule, String text) {
    for (final matcher in rule.inputMatchers) {
      if (matcher.isPartialMatch(text)) return true;
    }

    return false;
  }
}

/// Allows only whitespace-separated tokens from [ruleId].
///
/// Each completed segment must parse as exactly one token for the target rule.
/// The final segment may be an in-progress partial match, which lets users type
/// a new trigger such as `#` before the token is complete.
class TokenListOnlyFormatter extends TokenInputFormatter {
  const TokenListOnlyFormatter({
    required super.lexer,
    required this.ruleId,
  });

  final String ruleId;

  @override
  TextEditingValue formatAst(
    TextEditingValue oldValue,
    TextEditingValue newValue,
    List<TokenMatch> ast,
  ) {
    final trimmed = newValue.text.trim();
    if (trimmed.isEmpty) return newValue;

    final rule = _ruleFor(ruleId);
    if (rule == null) return oldValue;

    final segments = trimmed.split(RegExp(r'\s+'));
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isLast = i == segments.length - 1;

      if (_isExactToken(rule, segment)) {
        continue;
      }

      if (isLast && _isAllowedPartial(rule, segment)) {
        continue;
      }

      return oldValue;
    }

    return newValue;
  }

  TokenRule? _ruleFor(String id) {
    for (final rule in lexer.rules) {
      if (rule.id == id) return rule;
    }
    return null;
  }

  bool _isAllowedPartial(TokenRule rule, String text) {
    for (final matcher in rule.inputMatchers) {
      if (matcher.isPartialMatch(text)) return true;
    }
    return false;
  }

  bool _isExactToken(TokenRule rule, String text) {
    final matches = rule.matcher.findMatches(text, rule.id);
    for (final match in matches) {
      if (match.start == 0 && match.end == text.length) {
        return true;
      }
    }
    return false;
  }
}