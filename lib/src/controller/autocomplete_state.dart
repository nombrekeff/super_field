import '../lexer/token_match.dart';
import '../lexer/token_matcher.dart';

/// Describes the text range that triggered an autocomplete session and the
/// query extracted from it.
class AutocompleteTrigger {
  const AutocompleteTrigger({
    required this.triggerId,
    required this.activationMatcher,
  });

  /// A unique identifier for this trigger (e.g., `'mention_search'`).
  final String triggerId;

  /// The matcher that determines when this trigger becomes active.
  ///
  /// Typically a [StartsWithMatcher] (e.g., `StartsWithMatcher('@')`).
  final TokenMatcher activationMatcher;
}

/// Immutable snapshot of the autocomplete session state emitted by
/// [TokenEditingController] whenever the user types text that activates a
/// trigger.
class AutocompleteState {
  const AutocompleteState({
    required this.isActive,
    this.activeTriggerId,
    this.query,
    this.matchBounds,
  });

  /// Whether an autocomplete session is currently active.
  final bool isActive;

  /// The [AutocompleteTrigger.triggerId] of the active trigger, or `null`
  /// when [isActive] is `false`.
  final String? activeTriggerId;

  /// The search query typed after the trigger character (e.g., `'jo'` if the
  /// user typed `@jo`), or `null` when [isActive] is `false`.
  final String? query;

  /// The exact bounds of the trigger text in the raw string, or `null` when
  /// [isActive] is `false`.
  final TokenMatch? matchBounds;

  /// An inactive (closed) autocomplete state.
  static const inactive = AutocompleteState(isActive: false);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutocompleteState &&
          runtimeType == other.runtimeType &&
          isActive == other.isActive &&
          activeTriggerId == other.activeTriggerId &&
          query == other.query &&
          matchBounds == other.matchBounds;

  @override
  int get hashCode =>
      isActive.hashCode ^
      activeTriggerId.hashCode ^
      query.hashCode ^
      matchBounds.hashCode;

  @override
  String toString() =>
      'AutocompleteState(isActive: $isActive, triggerId: $activeTriggerId, '
      'query: $query)';
}
