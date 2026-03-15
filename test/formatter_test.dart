import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_field/super_field.dart';

void main() {
  group('AtomicDeletionFormatter', () {
    late AtomicDeletionFormatter formatter;
    late TokenLexer lexer;

    setUp(() {
      lexer = TokenLexer(rules: [_MentionRule()]);
      formatter = AtomicDeletionFormatter(lexer: lexer);
    });

    TextEditingValue apply(String oldText, String newText, int cursorOffset) {
      return formatter.formatEditUpdate(
        TextEditingValue(
          text: oldText,
          selection: TextSelection.collapsed(
              offset: oldText.length),
        ),
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: cursorOffset),
        ),
      );
    }

    test('deletes full token when backspace is pressed after atomic token', () {
      // "Hi <@1|John>!" — token "<@1|John>" spans [3, 12)
      // User presses backspace from cursor position 12 (just after '>'),
      // deleting the '>' at index 11.
      const old = 'Hi <@1|John>!';
      final result = apply(old, 'Hi <@1|John!', 11);

      expect(result.text, 'Hi !');
      expect(result.selection.baseOffset, 3);
    });

    test('does not modify text for insertion', () {
      const old = 'Hello';
      const newText = 'Hello!';
      final result = apply(old, newText, 6);
      expect(result.text, newText);
    });

    test('does not modify deletion outside of any token', () {
      const old = 'Hello World';
      const newText = 'Hello Worl';
      final result = apply(old, newText, 10);
      expect(result.text, newText);
    });

    test('does not modify deletion for transparent-behavior tokens', () {
      final transparentLexer =
          TokenLexer(rules: [_TransparentMentionRule()]);
      final transparentFormatter =
          AtomicDeletionFormatter(lexer: transparentLexer);
      const old = '<@1|John>';
      // Delete last char of token
      final result = transparentFormatter.formatEditUpdate(
        const TextEditingValue(
            text: old,
            selection: TextSelection.collapsed(offset: old.length)),
        const TextEditingValue(
            text: '<@1|John',
            selection: TextSelection.collapsed(offset: 8)),
      );
      // Should be returned as-is (transparent behavior)
      expect(result.text, '<@1|John');
    });

    test('handles deletion inside a token', () {
      // "Hi <@1|John>!" — token "<@1|John>" spans [3, 12)
      // Simulate user deleted 'J' at index 7, mid-token.
      const old = 'Hi <@1|John>!';
      final result = apply(old, 'Hi <@1|ohn>!', 7);
      // Full token should be removed since deletion is inside atomic token range
      expect(result.text, 'Hi !');
    });
  });
}

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _MentionRule extends TokenRule {
  @override
  String get id => 'mention';

  @override
  TokenMatcher get matcher => MarkupMatcher(tagPrefix: '@');

  @override
  TokenBehavior get behavior => TokenBehavior.atomic;

  @override
  InlineSpan buildSpan({
    required context,
    required match,
    required defaultStyle,
    required isReadOnly,
  }) =>
      TextSpan(text: match.groups[1]);
}

class _TransparentMentionRule extends TokenRule {
  @override
  String get id => 'mention';

  @override
  TokenMatcher get matcher => MarkupMatcher(tagPrefix: '@');

  @override
  TokenBehavior get behavior => TokenBehavior.transparent;

  @override
  InlineSpan buildSpan({
    required context,
    required match,
    required defaultStyle,
    required isReadOnly,
  }) =>
      TextSpan(text: match.groups[1]);
}
