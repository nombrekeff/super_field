import '../token_match.dart';
import '../token_matcher.dart';

/// A [TokenMatcher] for the "hidden markup" syntax used to embed an ID and a
/// display label inside a token (e.g., `<@123|John Doe>`).
///
/// ### Pattern
/// ```
/// <[prefix][id]|[label]>
/// ```
/// - The [tagPrefix] (e.g., `@`) distinguishes token types within the same
///   markup syntax.
/// - [TokenMatch.groups] contains `[id, label]`.
///
/// ### Example
/// ```dart
/// final matcher = MarkupMatcher(tagPrefix: '@');
/// // Matches "<@123|John Doe>" and yields groups: ["123", "John Doe"]
/// ```
class MarkupMatcher extends TokenMatcher {
  @override
  bool isPartialMatch(String text) {
    return text.startsWith("<$tagPrefix");
  }

  MarkupMatcher({required this.tagPrefix})
      : _pattern = RegExp(
          '<${RegExp.escape(tagPrefix)}([^|>]+)\\|([^>]+)>',
        );

  /// The character immediately after `<` that identifies the token type.
  final String tagPrefix;

  late final RegExp _pattern;

  @override
  Iterable<TokenMatch> findMatches(String text, String ruleId) sync* {
    for (final m in _pattern.allMatches(text)) {
      yield TokenMatch(
        start: m.start,
        end: m.end,
        fullText: m.group(0)!,
        groups: [m.group(1)!, m.group(2)!],
        ruleId: ruleId,
      );
    }
  }
}
