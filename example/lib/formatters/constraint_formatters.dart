import 'package:flutter/services.dart';
import 'package:super_field/super_field.dart';

/// Allows only one token of [ruleId] (plus optional surrounding whitespace).
class SingleTokenOnlyFormatter extends TokenInputFormatter {
  const SingleTokenOnlyFormatter({
    required super.lexer,
    required this.ruleId,
  });

  final String ruleId;
  static final RegExp _partialMentionPattern = RegExp(r'^@[^\s]*$');

  @override
  TextEditingValue formatAst(
    TextEditingValue oldValue,
    TextEditingValue newValue,
    List<TokenMatch> ast,
  ) {
    final trimmed = newValue.text.trim();
    if (trimmed.isEmpty) return newValue;
    if (_partialMentionPattern.hasMatch(trimmed)) return newValue;

    if (ast.length != 1) return oldValue;
    final token = ast.first;
    if (token.ruleId != ruleId) return oldValue;
    if (trimmed != token.fullText) return oldValue;
    return newValue;
  }
}

/// Allows only whitespace-separated hashtag tokens.
class HashtagListOnlyFormatter extends TokenInputFormatter {
  const HashtagListOnlyFormatter({
    required super.lexer,
    required this.ruleId,
  });

  final String ruleId;
  static final RegExp _hashtagTokenPattern = RegExp(r'^#[A-Za-z0-9_]+$');

  @override
  TextEditingValue formatAst(
    TextEditingValue oldValue,
    TextEditingValue newValue,
    List<TokenMatch> ast,
  ) {
    final text = newValue.text.trim();
    if (text.isEmpty) return newValue;

    final parts = text.split(RegExp(r'\s+'));
    final allValid = parts.every(_hashtagTokenPattern.hasMatch);
    if (!allValid) return oldValue;

    final hashtags = ast.where((m) => m.ruleId == ruleId).length;
    if (hashtags != parts.length) return oldValue;

    return newValue;
  }
}
