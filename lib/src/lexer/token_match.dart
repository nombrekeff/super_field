/// Represents a single match produced by a [TokenMatcher].
class TokenMatch {
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

  const TokenMatch({
    required this.start,
    required this.end,
    required this.fullText,
    required this.groups,
    required this.ruleId,
  });

  @override
  String toString() =>
      'TokenMatch(ruleId: $ruleId, start: $start, end: $end, fullText: $fullText)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenMatch &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          fullText == other.fullText &&
          ruleId == other.ruleId;

  @override
  int get hashCode =>
      start.hashCode ^ end.hashCode ^ fullText.hashCode ^ ruleId.hashCode;
}
