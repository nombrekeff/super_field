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
          selection: TextSelection.collapsed(offset: oldText.length),
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
      final transparentLexer = TokenLexer(rules: [_TransparentMentionRule()]);
      final transparentFormatter =
          AtomicDeletionFormatter(lexer: transparentLexer);
      const old = '<@1|John>';
      // Delete last char of token
      final result = transparentFormatter.formatEditUpdate(
        const TextEditingValue(
            text: old, selection: TextSelection.collapsed(offset: old.length)),
        const TextEditingValue(
            text: '<@1|John', selection: TextSelection.collapsed(offset: 8)),
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

    test('expands deletion that starts before an atomic token', () {
      const old = 'A <@1|John> B';
      // Simulate deleting from the start of the string through part of token.
      const newText = 'John> B';
      final result = apply(old, newText, 0);

      // Deletion overlaps token, so token must be removed fully too.
      expect(result.text, ' B');
      expect(result.selection.baseOffset, 0);
    });

    test('expands deletion that ends after an atomic token', () {
      const old = 'A <@1|John> B';
      // User deletes from inside token through following plain text.
      const newText = 'A <@1|Jo';
      final result = apply(old, newText, 8);

      // Token is removed completely while preserving unaffected text.
      expect(result.text, 'A ');
      expect(result.selection.baseOffset, 2);
    });

    test('removes all atomic tokens touched by an expanded deletion range', () {
      const old = '<@1|Alice><@2|Bob>!';
      // Simulate deleting the boundary between adjacent tokens.
      const newText = '<@1|AliceBob>!';
      final result = apply(old, newText, 8);

      expect(result.text, '!');
      expect(result.selection.baseOffset, 0);
    });
  });

  group('SingleTokenOnlyFormatter', () {
    final formatter = SingleTokenOnlyFormatter(
      lexer: TokenLexer(rules: [_AutocompleteMentionRule()]),
      ruleId: 'mention',
    );

    TextEditingValue apply({
      required String oldText,
      required String newText,
      required int cursorOffset,
    }) {
      return formatter.formatEditUpdate(
        TextEditingValue(
          text: oldText,
          selection: TextSelection.collapsed(offset: oldText.length),
        ),
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: cursorOffset),
        ),
      );
    }

    test('allows bare trigger input through rule input matchers', () {
      final result = apply(oldText: '', newText: '@', cursorOffset: 1);

      expect(result.text, '@');
    });

    test('allows completed token markup', () {
      const token = '<@1|Alice>';
      final result = apply(
        oldText: '@al',
        newText: token,
        cursorOffset: token.length,
      );

      expect(result.text, token);
    });

    test('rejects plain text', () {
      final result = apply(oldText: '', newText: 'alice', cursorOffset: 5);

      expect(result.text, '');
    });
  });

  group('TokenListOnlyFormatter', () {
    final formatter = TokenListOnlyFormatter(
      lexer: TokenLexer(rules: [_HashtagRule()]),
      ruleId: 'hashtag',
    );

    TextEditingValue apply({
      required String oldText,
      required String newText,
      required int cursorOffset,
    }) {
      return formatter.formatEditUpdate(
        TextEditingValue(
          text: oldText,
          selection: TextSelection.collapsed(offset: oldText.length),
        ),
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: cursorOffset),
        ),
      );
    }

    test('allows a bare trailing trigger', () {
      final result = apply(
        oldText: '#flutter ',
        newText: '#flutter #',
        cursorOffset: 10,
      );

      expect(result.text, '#flutter #');
    });

    test('allows completed whitespace-separated tokens', () {
      final result = apply(
        oldText: '#flutter #',
        newText: '#flutter #dart',
        cursorOffset: 14,
      );

      expect(result.text, '#flutter #dart');
    });

    test('rejects mixed plain text', () {
      final result = apply(
        oldText: '#flutter ',
        newText: '#flutter hello',
        cursorOffset: 14,
      );

      expect(result.text, '#flutter ');
    });
  });

  group('formatter and autocomplete integration', () {
    test('admitted partial mention input still activates autocomplete', () {
      final formatter = SingleTokenOnlyFormatter(
        lexer: TokenLexer(rules: [_AutocompleteMentionRule()]),
        ruleId: 'mention',
      );

      final controller = TokenEditingController(
        lexer: TokenLexer(rules: [_AutocompleteMentionRule()]),
        autocomplete: AutocompleteConfig(
          triggers: [
            const AutocompleteTrigger(
              triggerId: 'mention_search',
              activationMatcher: StartsWithMatcher('@'),
            ),
          ],
        ),
      );

      final formatted = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        ),
        const TextEditingValue(
          text: '@al',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );

      controller.value = formatted;

      expect(controller.text, '@al');
      expect(controller.autocompleteState.isActive, isTrue);
      expect(controller.autocompleteState.query, 'al');

      controller.dispose();
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

class _AutocompleteMentionRule extends TokenRule {
  @override
  String get id => 'mention';

  @override
  TokenMatcher get matcher => MarkupMatcher(tagPrefix: '@');

  @override
  Iterable<TokenMatcher> get inputMatchers => [
        const StartsWithMatcher('@'),
        MarkupMatcher(tagPrefix: '@'),
      ];

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

class _HashtagRule extends TokenRule {
  @override
  String get id => 'hashtag';

  @override
  TokenMatcher get matcher => const StartsWithMatcher('#');

  @override
  TokenBehavior get behavior => TokenBehavior.transparent;

  @override
  InlineSpan buildSpan({
    required context,
    required match,
    required defaultStyle,
    required isReadOnly,
  }) =>
      TextSpan(text: match.fullText);
}
