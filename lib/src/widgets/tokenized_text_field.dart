import 'package:flutter/material.dart';

import '../controller/autocomplete_state.dart';
import '../controller/token_editing_controller.dart';
import '../formatters/atomic_deletion_formatter.dart';
import '../lexer/token_match.dart';
import '../lexer/token_rule.dart';

/// A text field that renders interactive token widgets inline with plain text.
///
/// Mirrors the API of Flutter's [TextField] and adds:
/// - Atomic token cursor-guard via [TokenEditingController].
/// - Autocomplete trigger management.
/// - A [readOnly] mode that renders a non-editable, selectable rich-text view.
///
/// ### Mobile IME Protection
/// [autocorrect] is always `false` and [enableSuggestions] is always `false`
/// to prevent predictive text from corrupting hidden markup in the raw string.
class TokenizedTextField extends StatefulWidget {
  /// The controller that holds the raw text and exposes token utilities.
  final TokenEditingController controller;

  /// When `true`, renders the field as a selectable, non-editable rich text
  /// display, removing the need for a separate read-only widget.
  final bool readOnly;

  /// Standard Flutter decoration applied to the field.
  final InputDecoration? decoration;

  /// Text style applied to non-token runs of text.
  final TextStyle? style;

  /// Maximum number of lines. Pass `null` for unlimited.
  final int? maxLines;

  /// Focus node shared with parent widgets.
  final FocusNode? focusNode;

  /// Called with the raw string whenever the text changes.
  final ValueChanged<String>? onChanged;

  /// Autocomplete triggers evaluated by the controller on every keystroke.
  final List<AutocompleteTrigger> autocompleteTriggers;

  /// Called whenever the [AutocompleteState] changes.
  final ValueChanged<AutocompleteState>? onAutocompleteChange;

  const TokenizedTextField({
    super.key,
    required this.controller,
    this.readOnly = false,
    this.decoration,
    this.style,
    this.maxLines = 1,
    this.focusNode,
    this.onChanged,
    this.autocompleteTriggers = const [],
    this.onAutocompleteChange,
  });

  @override
  State<TokenizedTextField> createState() => _TokenizedTextFieldState();
}

class _TokenizedTextFieldState extends State<TokenizedTextField> {
  late AtomicDeletionFormatter _atomicFormatter;

  @override
  void initState() {
    super.initState();
    _atomicFormatter =
        AtomicDeletionFormatter(lexer: widget.controller.lexer);
  }

  @override
  void didUpdateWidget(TokenizedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.lexer != widget.controller.lexer) {
      _atomicFormatter =
          AtomicDeletionFormatter(lexer: widget.controller.lexer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        widget.style ?? DefaultTextStyle.of(context).style;

    if (widget.readOnly) {
      return _ReadOnlyTokenField(
        controller: widget.controller,
        style: effectiveStyle,
        decoration: widget.decoration,
        focusNode: widget.focusNode,
        maxLines: widget.maxLines,
      );
    }

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      style: effectiveStyle,
      decoration: widget.decoration,
      maxLines: widget.maxLines,
      // Mobile IME protection — must always be false.
      autocorrect: false,
      enableSuggestions: false,
      onChanged: widget.onChanged,
      inputFormatters: [_atomicFormatter],
    );
  }
}

// ---------------------------------------------------------------------------
// Read-only display
// ---------------------------------------------------------------------------

class _ReadOnlyTokenField extends StatelessWidget {
  final TokenEditingController controller;
  final TextStyle style;
  final InputDecoration? decoration;
  final FocusNode? focusNode;
  final int? maxLines;

  const _ReadOnlyTokenField({
    required this.controller,
    required this.style,
    this.decoration,
    this.focusNode,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final richText = _buildRichText(context);
    final child = SelectableText.rich(
      richText,
      style: style,
      focusNode: focusNode,
      maxLines: maxLines,
    );

    if (decoration != null) {
      return InputDecorator(
        decoration: decoration!,
        child: child,
      );
    }
    return child;
  }

  TextSpan _buildRichText(BuildContext context) {
    final ast = controller.currentAst;
    final text = controller.text;

    if (ast.isEmpty) {
      return TextSpan(text: text);
    }

    final spans = <InlineSpan>[];
    int cursor = 0;

    for (final match in ast) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final rule = _ruleFor(match, controller);
      if (rule != null) {
        spans.add(rule.buildSpan(
          context: context,
          match: match,
          defaultStyle: style,
          isReadOnly: true,
        ));
      } else {
        spans.add(TextSpan(text: match.fullText));
      }
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return TextSpan(children: spans);
  }

  TokenRule? _ruleFor(TokenMatch match, TokenEditingController controller) {
    try {
      return controller.lexer.rules.firstWhere((r) => r.id == match.ruleId);
    } catch (_) {
      return null;
    }
  }
}
