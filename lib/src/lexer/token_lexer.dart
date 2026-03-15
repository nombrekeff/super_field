import 'token_match.dart';
import 'token_rule.dart';

/// Parses a plain string into a flat list of [TokenMatch]es (the AST).
///
/// Rules are applied in the order they appear in [rules]. The first rule to
/// claim a segment of text "wins" — later rules cannot overlap with already
/// matched ranges.
class TokenLexer {
  const TokenLexer({required this.rules});

  /// The ordered list of rules used during parsing.
  final List<TokenRule> rules;

  /// Parses [text] and returns a flat, non-overlapping, position-ordered list
  /// of [TokenMatch]es.
  List<TokenMatch> parse(String text) {
    if (text.isEmpty) return const [];

    final claimed = <_Interval>[];
    final matches = <TokenMatch>[];

    for (final rule in rules) {
      for (final match in rule.matcher.findMatches(text, rule.id)) {
        if (!_isClaimed(match.start, match.end, claimed)) {
          claimed.add(_Interval(match.start, match.end));
          matches.add(match);
        }
      }
    }

    matches.sort((a, b) => a.start.compareTo(b.start));
    return List.unmodifiable(matches);
  }

  bool _isClaimed(int start, int end, List<_Interval> claimed) {
    for (final interval in claimed) {
      if (start < interval.end && end > interval.start) return true;
    }
    return false;
  }
}

class _Interval {
  const _Interval(this.start, this.end);

  final int start;
  final int end;
}
