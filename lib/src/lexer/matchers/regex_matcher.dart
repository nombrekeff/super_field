import '../token_match.dart';
import '../token_matcher.dart';

/// A [TokenMatcher] that finds tokens using a [RegExp].
///
/// Every capture group in the pattern is surfaced as an entry in
/// [TokenMatch.groups].
class RegexMatcher extends TokenMatcher {
  const RegexMatcher(this.pattern);
  
  @override
  bool isPartialMatch(String text) {
    return pattern.hasMatch(text);
  }

  /// The regular expression used to locate tokens.
  final RegExp pattern;

  @override
  Iterable<TokenMatch> findMatches(String text, String ruleId) sync* {
    for (final m in pattern.allMatches(text)) {
      yield TokenMatch(
        start: m.start,
        end: m.end,
        fullText: m.group(0)!,
        groups: [
          for (int i = 1; i <= m.groupCount; i++) m.group(i) ?? '',
        ],
        ruleId: ruleId,
      );
    }
  }
}
