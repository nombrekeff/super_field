import '../token_match.dart';
import '../token_matcher.dart';

/// A [TokenMatcher] that matches contiguous word-like sequences that begin
/// with a given [trigger] character (e.g., `@` for mentions or `#` for
/// hashtags).
///
/// A "word" is defined as any run of non-whitespace characters that
/// immediately follows the trigger without any separating space.
class StartsWithMatcher extends TokenMatcher {
  /// The character (or short string) that introduces the token.
  final String trigger;

  static final _whitespace = RegExp(r'\s');

  const StartsWithMatcher(this.trigger);

  @override
  Iterable<TokenMatch> findMatches(String text, String ruleId) sync* {
    int i = 0;
    while (i < text.length) {
      if (text.startsWith(trigger, i)) {
        int end = i + trigger.length;
        while (end < text.length && !_whitespace.hasMatch(text[end])) {
          end++;
        }
        if (end > i + trigger.length) {
          yield TokenMatch(
            start: i,
            end: end,
            fullText: text.substring(i, end),
            groups: [text.substring(i + trigger.length, end)],
            ruleId: ruleId,
          );
        }
        i = end;
      } else {
        i++;
      }
    }
  }
}
