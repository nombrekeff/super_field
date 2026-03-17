import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_field/super_field.dart';

/// A text field that renders interactive token widgets inline with plain text.
///
/// Mirrors the API of Flutter's [TextField] and adds:
/// - Atomic token cursor-guard via [TokenEditingController].
/// - A [readOnly] mode that renders a non-editable, selectable rich-text view.
///
/// Autocomplete triggers and callbacks are configured directly on the
/// [TokenEditingController], keeping the widget API lean.
///
/// ### Mobile IME Protection
/// [autocorrect] is always `false` and [enableSuggestions] is always `false`
/// to prevent predictive text from corrupting hidden markup in the raw string.
class TokenizedTextField extends StatefulWidget {
  const TokenizedTextField({
    super.key,
    required this.controller,
    this.readOnly = false,
    this.decoration,
    this.style,
    this.maxLines = 1,
    this.focusNode,
    this.onChanged,
    this.inputFormatters = const [],
  });

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

  /// Additional input formatters applied after atomic deletion handling.
  ///
  /// This enables declarative constraints (for example: single-token-only
  /// fields) without relying on form error messages.
  final List<TextInputFormatter> inputFormatters;

  @override
  State<TokenizedTextField> createState() => _TokenizedTextFieldState();
}

class _TokenizedTextFieldState extends State<TokenizedTextField> {
  late AtomicDeletionFormatter _atomicFormatter;

  @override
  void initState() {
    super.initState();
    _atomicFormatter = AtomicDeletionFormatter(lexer: widget.controller.lexer);
  }

  @override
  void didUpdateWidget(TokenizedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.lexer != widget.controller.lexer) {
      _atomicFormatter = AtomicDeletionFormatter(lexer: widget.controller.lexer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = widget.style ?? DefaultTextStyle.of(context).style;

    return Autocompletable(
      controller: widget.controller,
      child: TextField(
        readOnly: widget.readOnly,
        controller: widget.controller,
        focusNode: widget.focusNode,
        style: effectiveStyle,
        decoration: widget.decoration,
        maxLines: widget.maxLines,
        // Mobile IME protection — must always be false.
        autocorrect: false,
        enableSuggestions: false,
        selectAllOnFocus: false,
        onChanged: widget.onChanged,
        inputFormatters: [_atomicFormatter, ...widget.inputFormatters],
      ),
    );
  }
}
