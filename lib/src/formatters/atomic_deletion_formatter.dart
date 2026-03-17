import 'package:flutter/services.dart';

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

    final deletedRange = _findDeletedRange(oldValue.text, newValue.text);
    
    if (deletedRange == null) return newValue;
    final deletedStart = deletedRange.$1;
    final deletedEnd = deletedRange.$2;

    int expandedStart = deletedStart;
    int expandedEnd = deletedEnd;
    bool hasAtomicOverlap = false;

    // Lexer output is position-ordered and non-overlapping, so once we pass
    // the current expanded deletion end we can stop scanning.
    for (final match in atomicMatches) {
      if (match.end <= expandedStart) {
        continue;
      }
      if (match.start >= expandedEnd) {
        break;
      }
      if (_rangesOverlap(expandedStart, expandedEnd, match.start, match.end)) {
        hasAtomicOverlap = true;
        if (match.start < expandedStart) {
          expandedStart = match.start;
        }
        if (match.end > expandedEnd) {
          expandedEnd = match.end;
        }
      }
    }

    if (!hasAtomicOverlap) return newValue;

    final stripped =
        oldValue.text.substring(0, expandedStart) +
        oldValue.text.substring(expandedEnd);
    return TextEditingValue(
      text: stripped,
      selection: TextSelection.collapsed(offset: expandedStart),
    );
  }

  bool _isAtomic(TokenMatch match) {
    try {
      final rule = _rules.firstWhere((r) => r.id == match.ruleId);
      return rule.behavior == TokenBehavior.atomic;
    } catch (_) {
      return false;
    }
  }

  /// Returns the deleted `[start, end)` range in [oldText], or `null` if
  /// the change is not a single contiguous deletion.
  (int, int)? _findDeletedRange(String oldText, String newText) {
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
      return (prefixLen, suffixStart);
    }

    return null;
  }

  /// Returns `true` when the two half-open ranges `[startA, endA)` and
  /// `[startB, endB)` share at least one index.
  bool _rangesOverlap(
    int startA,
    int endA,
    int startB,
    int endB,
  ) => startA < endB && startB < endA;
}
