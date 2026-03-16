import 'package:flutter/widgets.dart';

import '../lexer/token_lexer.dart';
import '../lexer/token_match.dart';
import '../lexer/token_rule.dart';
import 'autocomplete_state.dart';

/// A [TextEditingController] that understands token markup.
///
/// It:
/// - Keeps a parsed AST of the current text.
/// - Sanitizes cursor/selection positions so they cannot land inside
///   [TokenBehavior.atomic] tokens.
/// - Tracks autocomplete trigger state and notifies via [onAutocompleteChange].
/// - Provides data-extraction helpers ([getMatchesByRule], [getPlainText]).
class TokenEditingController extends TextEditingController {
  TokenEditingController({
    required this.lexer,
    super.text,
    this.autocompleteTriggers = const [],
    this.onAutocompleteChange,
  }) {
    _ast = lexer.parse(text);
  }

  /// The lexer used to parse the raw text into a flat AST.
  final TokenLexer lexer;

  /// Optional autocomplete triggers evaluated after every text change.
  final List<AutocompleteTrigger> autocompleteTriggers;

  /// Callback invoked whenever the [AutocompleteState] changes.
  final ValueChanged<AutocompleteState>? onAutocompleteChange;

  List<TokenMatch> _ast = const [];
  AutocompleteState _autocompleteState = AutocompleteState.inactive;

  /// The current flat AST of the text.
  List<TokenMatch> get currentAst => _ast;

  /// The current autocomplete state.
  AutocompleteState get autocompleteState => _autocompleteState;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final effectiveStyle = style ?? const TextStyle();
    final textValue = value;

    if (_ast.isEmpty) {
      return TextSpan(style: effectiveStyle, text: text);
    }

    final spans = <InlineSpan>[];
    int cursor = 0;

    for (final match in _ast) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: text.substring(cursor, match.start),
            style: effectiveStyle,
          ),
        );
      }

      final rule = _ruleFor(match);
      if (rule != null) {
        final InlineSpan tokenSpan = rule.buildSpan(
          context: context,
          match: match,
          defaultStyle: effectiveStyle,
          isReadOnly: false,
        );

        // Ensure the rendered span contributes the same plain-text length as
        // the underlying raw token text. This keeps selection/caret offsets,
        // which are computed against `toPlainText()`, in sync with the raw
        // `match.start`/`match.end` offsets used by the controller.
        final int renderedLength = tokenSpan.toPlainText().length;
        final int rawLength = match.fullText.length;

        if (renderedLength == rawLength) {
          spans.add(tokenSpan);
        } else if (renderedLength < rawLength) {
          // Pad with zero-width characters so the span's plain-text length
          // matches the raw token length, without changing visible output.
          final int padCount = rawLength - renderedLength;
          final String padding = '\u200B' * padCount;
          spans.add(
            TextSpan(
              children: <InlineSpan>[
                tokenSpan,
                TextSpan(text: padding, style: effectiveStyle),
              ],
            ),
          );
        } else {
          // If the rendered text is longer than the raw token, fall back to
          // rendering the raw token text to keep lengths consistent.
          spans.add(TextSpan(text: match.fullText, style: effectiveStyle));
        }
      } else {
        spans.add(TextSpan(text: match.fullText, style: effectiveStyle));
      }
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: effectiveStyle));
    }

    List<InlineSpan> finalSpans = spans;
    if (withComposing &&
        textValue.isComposingRangeValid &&
        !textValue.composing.isCollapsed) {
      finalSpans = _applyComposingToSpans(
        spans,
        textValue.composing,
        effectiveStyle,
      );
    }

    return TextSpan(style: effectiveStyle, children: finalSpans);
  }

  List<InlineSpan> _applyComposingToSpans(
    List<InlineSpan> spans,
    TextRange composing,
    TextStyle defaultStyle,
  ) {
    final List<InlineSpan> result = <InlineSpan>[];
    int offset = 0;

    for (final span in spans) {
      final spanText = span.toPlainText();
      final spanLength = spanText.length;
      final spanStart = offset;
      final spanEnd = spanStart + spanLength;
      offset = spanEnd;

      if (spanLength == 0 ||
          composing.end <= spanStart ||
          composing.start >= spanEnd) {
        result.add(span);
        continue;
      }

      if (span is TextSpan && span.children == null && span.text != null) {
        final localStart = (composing.start - spanStart).clamp(0, spanLength);
        final localEnd = (composing.end - spanStart).clamp(0, spanLength);
        final spanStyle = span.style ?? defaultStyle;

        if (localStart > 0) {
          result.add(
            TextSpan(
              text: spanText.substring(0, localStart),
              style: spanStyle,
            ),
          );
        }

        result.add(
          TextSpan(
            text: spanText.substring(localStart, localEnd),
            style: spanStyle.merge(
              const TextStyle(decoration: TextDecoration.underline),
            ),
          ),
        );

        if (localEnd < spanLength) {
          result.add(
            TextSpan(
              text: spanText.substring(localEnd),
              style: spanStyle,
            ),
          );
        }
      } else {
        result.add(span);
      }
    }

    return result;
  }

  @override
  set value(TextEditingValue newValue) {
    // Capture the pre-update value so selection sanitization can detect
    // history-driven text replacements (undo/redo) vs. caret moves.
    final oldValue = value;
    final newAst = lexer.parse(newValue.text);
    _ast = newAst;

    final sanitized = _sanitizeSelection(oldValue, newValue, newAst);
    super.value = newValue.copyWith(selection: sanitized);

    // Only run autocomplete when the selection is collapsed (no range selected).
    // Use extentOffset — the caret position in Flutter's selection model.
    if (sanitized.isCollapsed) {
      _updateAutocompleteState(newValue.text, sanitized.extentOffset);
    } else {
      _setAutocompleteState(AutocompleteState.inactive);
    }
  }

  // ---------------------------------------------------------------------------
  // Cursor guard
  // ---------------------------------------------------------------------------

  TextSelection _sanitizeSelection(
    TextEditingValue oldValue,
    TextEditingValue newValue,
    List<TokenMatch> ast,
  ) {
    final oldSelection = oldValue.selection;
    final newSelection = newValue.selection;
    final textChanged = oldValue.text != newValue.text;

    final atomicTokens = ast.where(
      (m) => _ruleFor(m)?.behavior == TokenBehavior.atomic,
    );

    int base = _sanitizeOffset(
      oldOffset: oldSelection.baseOffset,
      newOffset: newSelection.baseOffset,
      maxOffset: newValue.text.length,
      textChanged: textChanged,
      atomicTokens: atomicTokens,
    );
    int extent = _sanitizeOffset(
      oldOffset: oldSelection.extentOffset,
      newOffset: newSelection.extentOffset,
      maxOffset: newValue.text.length,
      textChanged: textChanged,
      atomicTokens: atomicTokens,
    );

    return newSelection.copyWith(baseOffset: base, extentOffset: extent);
  }

  int _sanitizeOffset({
    required int oldOffset,
    required int newOffset,
    required int maxOffset,
    required bool textChanged,
    required Iterable<TokenMatch> atomicTokens,
  }) {
    if (newOffset < 0) {
      return oldOffset.clamp(0, maxOffset);
    }

    for (final token in atomicTokens) {
      if (newOffset > token.start && newOffset < token.end) {
        if (textChanged) {
          final distanceToStart = (oldOffset - token.start).abs();
          final distanceToEnd = (oldOffset - token.end).abs();
          return distanceToStart <= distanceToEnd ? token.start : token.end;
        }

        // Determine direction: if moving forward, snap to end; else snap to start.
        if (newOffset >= oldOffset) {
          return token.end;
        } else {
          return token.start;
        }
      }
    }
    return newOffset.clamp(0, maxOffset);
  }

  TokenRule? _ruleFor(TokenMatch match) {
    try {
      return lexer.rules.firstWhere((r) => r.id == match.ruleId);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Autocomplete tracking
  // ---------------------------------------------------------------------------

  void _updateAutocompleteState(String text, int cursorOffset) {
    if (autocompleteTriggers.isEmpty) {
      _setAutocompleteState(AutocompleteState.inactive);
      return;
    }

    // Extract the word segment ending at the cursor position.
    final before = cursorOffset >= 0 && cursorOffset <= text.length
        ? text.substring(0, cursorOffset)
        : '';

    // Find the last word (no whitespace) ending at the cursor.
    final lastWordMatch = RegExp(r'\S+$').firstMatch(before);
    if (lastWordMatch == null) {
      _setAutocompleteState(AutocompleteState.inactive);
      return;
    }

    final word = lastWordMatch.group(0)!;
    final wordStart = lastWordMatch.start;

    for (final trigger in autocompleteTriggers) {
      final triggerMatches = trigger.activationMatcher
          .findMatches(word, trigger.triggerId)
          .toList();

      if (triggerMatches.isNotEmpty) {
        final m = triggerMatches.first;
        // Only activate when the match starts at position 0 of `word`.
        if (m.start == 0) {
          final query = m.groups.isNotEmpty ? m.groups.first : word;
          final state = AutocompleteState(
            isActive: true,
            activeTriggerId: trigger.triggerId,
            query: query,
            matchBounds: TokenMatch(
              start: wordStart,
              end: wordStart + word.length,
              fullText: word,
              groups: [query],
              ruleId: trigger.triggerId,
            ),
          );
          _setAutocompleteState(state);
          return;
        }
      }
    }

    _setAutocompleteState(AutocompleteState.inactive);
  }

  void _setAutocompleteState(AutocompleteState state) {
    if (_autocompleteState != state) {
      _autocompleteState = state;
      onAutocompleteChange?.call(state);
    }
  }

  // ---------------------------------------------------------------------------
  // Data extraction API
  // ---------------------------------------------------------------------------

  /// Returns all [TokenMatch]es produced by the rule with the given [ruleId].
  List<TokenMatch> getMatchesByRule(String ruleId) =>
      _ast.where((m) => m.ruleId == ruleId).toList(growable: false);

  /// Returns the document as plain text by converting each token via
  /// [TokenRule.toPlainText] and keeping non-token segments as-is.
  String getPlainText() {
    if (_ast.isEmpty) return text;

    final buffer = StringBuffer();
    int cursor = 0;

    for (final match in _ast) {
      if (match.start > cursor) {
        buffer.write(text.substring(cursor, match.start));
      }
      final rule = _ruleFor(match);
      buffer.write(rule != null ? rule.toPlainText(match) : match.fullText);
      cursor = match.end;
    }

    if (cursor < text.length) {
      buffer.write(text.substring(cursor));
    }

    return buffer.toString();
  }

  /// Replaces the text range defined by [match] with [replacement] and moves
  /// the cursor to the end of the inserted text.
  ///
  /// Typically used by autocomplete to insert a fully-formed token.
  void replaceMatch(TokenMatch match, String replacement) {
    final newText = text.replaceRange(match.start, match.end, replacement);
    final newOffset = match.start + replacement.length;
    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
