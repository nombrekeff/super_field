import 'package:flutter/services.dart';

import '../lexer/token_lexer.dart';
import '../lexer/token_match.dart';
import '../lexer/token_rule.dart';
import 'token_input_formatter.dart';

/// A mandatory formatter that enforces atomic deletion of tokens whose
/// [TokenBehavior] is [TokenBehavior.atomic].
///
/// When any contiguous deletion overlaps with the range of an atomic token
/// (i.e., one or more characters inside `[match.start, match.end)` are
/// removed), this formatter strips the **entire** token from the string.
/// This ensures a single backspace keypress always removes a whole token
/// rather than exposing internal markup characters.
class AtomicDeletionFormatter extends TokenInputFormatter {
  AtomicDeletionFormatter({required super.lexer})
      : _rules = lexer.rules;

  final List<TokenRule> _rules;

  @override
  TextEditingValue formatAst(
    TextEditingValue oldValue,
    TextEditingValue newValue,
    List<TokenMatch> ast,
  ) {
    // Only act when text was deleted (not inserted or unchanged).
    if (newValue.text.length >= oldValue.text.length) return newValue;

    // Parse the OLD AST to find atomic tokens in the original string.
    final oldAst = lexer.parse(oldValue.text);
    final atomicMatches =
        oldAst.where((m) => _isAtomic(m)).toList(growable: false);

    // Compute the deletion point once — it only depends on the two text values.
    final deletedAt = _findDeletionPoint(oldValue.text, newValue.text);
    if (deletedAt == null) return newValue;

    for (final match in atomicMatches) {
      if (deletedAt >= match.start && deletedAt < match.end) {
        // Strip the entire token from the old text.
        final stripped =
            oldValue.text.substring(0, match.start) +
            oldValue.text.substring(match.end);
        return TextEditingValue(
          text: stripped,
          selection: TextSelection.collapsed(offset: match.start),
        );
      }
    }

    return newValue;
  }

  bool _isAtomic(TokenMatch match) {
    try {
      final rule = _rules.firstWhere((r) => r.id == match.ruleId);
      return rule.behavior == TokenBehavior.atomic;
    } catch (_) {
      return false;
    }
  }

  /// Returns the index in [newText] where the deletion happened, or `null`
  /// if the change is not a single contiguous deletion.
  int? _findDeletionPoint(String oldText, String newText) {
    final deletedCount = oldText.length - newText.length;
    if (deletedCount <= 0) return null;

    // Find where the two strings diverge.
    int prefixLen = 0;
    while (prefixLen < newText.length &&
        prefixLen < oldText.length &&
        oldText[prefixLen] == newText[prefixLen]) {
      prefixLen++;
    }

    // Verify the suffix matches.
    final suffixStart = prefixLen + deletedCount;
    if (oldText.substring(suffixStart) == newText.substring(prefixLen)) {
      return prefixLen;
    }

    return null;
  }
}
