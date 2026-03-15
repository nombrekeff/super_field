import '../token_match.dart';
import '../token_matcher.dart';

/// A [TokenMatcher] that matches text enclosed between a [prefix] and a
/// [suffix] string (e.g., `**bold**` with prefix `**` and suffix `**`).
///
/// The content between the delimiters is surfaced as the first element of
/// [TokenMatch.groups].
class SurroundedByMatcher extends TokenMatcher {
  /// The opening delimiter.
  final String prefix;

  /// The closing delimiter.
  final String suffix;

  const SurroundedByMatcher({required this.prefix, required this.suffix});

  @override
  Iterable<TokenMatch> findMatches(String text, String ruleId) sync* {
    int searchFrom = 0;
    while (searchFrom < text.length) {
      final start = text.indexOf(prefix, searchFrom);
      if (start == -1) break;

      final contentStart = start + prefix.length;
      final end = text.indexOf(suffix, contentStart);
      if (end == -1) break;

      final tokenEnd = end + suffix.length;
      yield TokenMatch(
        start: start,
        end: tokenEnd,
        fullText: text.substring(start, tokenEnd),
        groups: [text.substring(contentStart, end)],
        ruleId: ruleId,
      );
      searchFrom = tokenEnd;
    }
  }
}
