import 'token_match.dart';

/// Abstract base for finding token patterns within a string.
///
/// Implement this class to define custom matching strategies, such as
/// matching against a local database or a complex grammar rule.
abstract class TokenMatcher {
  const TokenMatcher();

  /// Returns all non-overlapping [TokenMatch]es found in [text].
  ///
  /// The [ruleId] should be propagated to every [TokenMatch] produced.
  Iterable<TokenMatch> findMatches(String text, String ruleId);
}
