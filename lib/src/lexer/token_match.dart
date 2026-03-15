/// Represents a single match produced by a [TokenMatcher].
class TokenMatch {
  const TokenMatch({
    required this.start,
    required this.end,
    required this.fullText,
    required this.groups,
    required this.ruleId,
  });

  /// The start index (inclusive) of the match within the source text.
  final int start;

  /// The end index (exclusive) of the match within the source text.
  final int end;

  /// The full matched text including any syntax characters (e.g., `<@123|John>`).
  final String fullText;

  /// Captured groups extracted by the matcher (e.g., `["123", "John"]`).
  final List<String> groups;

  /// The [id] of the [TokenRule] that produced this match.
  final String ruleId;

  @override
  String toString() =>
      'TokenMatch(ruleId: $ruleId, start: $start, end: $end, fullText: $fullText)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TokenMatch) return false;
    if (other.start != start ||
        other.end != end ||
        other.fullText != fullText ||
        other.ruleId != ruleId) return false;
    if (groups.length != other.groups.length) return false;
    for (int i = 0; i < groups.length; i++) {
      if (groups[i] != other.groups[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([start, end, fullText, ruleId, ...groups]);
}
