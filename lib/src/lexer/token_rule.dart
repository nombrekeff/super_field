import 'package:flutter/widgets.dart';

import 'token_match.dart';
import 'token_matcher.dart';

/// Defines whether a token is navigated character-by-character or atomically.
enum TokenBehavior {
  /// The cursor can enter and exit the token normally, treating every character
  /// as a standard text character.
  transparent,

  /// The cursor snaps over the entire token. A single backspace press deletes
  /// the entire token rather than its last character.
  atomic,
}

/// The core configuration object that describes how a type of token is
/// detected, rendered, and behaves inside the text field.
abstract class TokenRule {
  const TokenRule();

  /// Unique identifier for this rule (e.g., `'mention'`, `'hashtag'`).
  String get id;

  /// The matcher used to locate this token type within the text.
  TokenMatcher get matcher;

  /// Defines cursor movement and deletion behaviour for matched tokens.
  TokenBehavior get behavior;

  /// Builds the visual representation of a token.
  ///
  /// [isReadOnly] allows rendering a bordered chip while editing, but flat
  /// coloured text when the field is read-only.
  InlineSpan buildSpan({
    required BuildContext context,
    required TokenMatch match,
    required TextStyle defaultStyle,
    required bool isReadOnly,
  });

  /// Returns the plain-text representation used when the token is copied to
  /// the clipboard or when [TokenEditingController.getPlainText] is called.
  ///
  /// Defaults to [TokenMatch.fullText].
  String toPlainText(TokenMatch match) => match.fullText;
}
