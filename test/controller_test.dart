import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_field/super_field.dart';

void main() {
  group('TokenEditingController', () {
    late TokenEditingController controller;

    setUp(() {
      controller = TokenEditingController(
        lexer: TokenLexer(rules: [_MentionRule()]),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('currentAst is empty for empty text', () {
      expect(controller.currentAst, isEmpty);
    });

    test('currentAst is populated after setting value', () {
      controller.text = 'Hello <@1|John>!';
      expect(controller.currentAst.length, 1);
    });

    test('getMatchesByRule returns correct matches', () {
      controller.text = '<@1|Alice> and <@2|Bob>';
      final mentions = controller.getMatchesByRule('mention');
      expect(mentions.length, 2);
    });

    test('getMatchesByRule returns empty list for unknown rule', () {
      controller.text = '<@1|Alice>';
      expect(controller.getMatchesByRule('nonexistent'), isEmpty);
    });

    test('getPlainText converts tokens via toPlainText', () {
      controller.text = 'Hi <@1|John>!';
      expect(controller.getPlainText(), 'Hi @John!');
    });

    test('getPlainText returns raw text when no tokens', () {
      controller.text = 'Plain text';
      expect(controller.getPlainText(), 'Plain text');
    });

    test('replaceMatch inserts replacement and positions cursor', () {
      controller.text = 'Hello @jo';
      const match = TokenMatch(
        start: 6,
        end: 9,
        fullText: '@jo',
        groups: ['jo'],
        ruleId: 'mention_trigger',
      );
      controller.replaceMatch(match, '<@1|John> ');
      expect(controller.text, 'Hello <@1|John> ');
      expect(controller.selection.baseOffset, 16);
    });

    testWidgets('buildTextSpan handles composing ranges', (tester) async {
      controller.value = const TextEditingValue(
        text: 'Hi <@1|John>!',
        selection: TextSelection.collapsed(offset: 13),
        composing: TextRange(start: 0, end: 2),
      );

      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));

      final span = controller.buildTextSpan(
        context: context,
        withComposing: true,
      );

      final underlinedTextSpans = (span.children ?? const <InlineSpan>[])
          .whereType<TextSpan>()
          .where((s) => s.style?.decoration == TextDecoration.underline);

      expect(underlinedTextSpans, isNotEmpty);
    });

    group('cursor sanitization', () {
      test('cursor inside atomic token snaps forward when moving forward', () {
        // Text: "Hi <@1|John>!" — token "<@1|John>" spans [3, 12)
        controller.value = const TextEditingValue(
          text: 'Hi <@1|John>!',
          selection: TextSelection.collapsed(offset: 5),
          // Cursor at position 5 is inside the token [3, 12)
        );
        // Expect cursor snapped to end of token (12)
        expect(controller.selection.baseOffset, 12);
      });

      test('cursor inside atomic token snaps backward when moving backward', () {
        // Simulate cursor was at position 13 (end of string), now moves to 7
        // (inside the token [3, 12)). The old offset (13) > new offset (7)
        // so it is a backward movement.
        const oldValue = TextEditingValue(
          text: 'Hi <@1|John>!',
          selection: TextSelection.collapsed(offset: 13),
        );
        // Set up old value first (13 is not inside the token, no snapping)
        controller.value = oldValue;

        // Now set a new value where cursor moves backward into the token
        controller.value = const TextEditingValue(
          text: 'Hi <@1|John>!',
          selection: TextSelection.collapsed(offset: 7),
        );
        // Expect cursor snapped to start of token (3)
        expect(controller.selection.baseOffset, 3);
      });

      test('text replacement keeps cursor near previous side of token', () {
        // Simulate a delete + undo cycle.
        controller.value = const TextEditingValue(
          text: 'Hi !',
          selection: TextSelection.collapsed(offset: 3),
        );

        controller.value = const TextEditingValue(
          text: 'Hi <@1|John>!',
          selection: TextSelection.collapsed(offset: 7),
        );

        // Cursor offset 7 is inside token [3, 12), but after history restore
        // it should stay near the previous cursor side (offset 3, token start),
        // not jump to token end.
        expect(controller.selection.baseOffset, 3);
      });

      test('invalid selection is clamped to a valid offset', () {
        controller.value = const TextEditingValue(
          text: 'Hi <@1|John>!',
          selection: TextSelection.collapsed(offset: 12),
        );

        controller.value = const TextEditingValue(
          text: 'Hi <@1|John>!',
          selection: TextSelection.collapsed(offset: -1),
        );

        expect(controller.selection.baseOffset, 12);
        expect(controller.selection.extentOffset, 12);
        expect(controller.selection.isValid, isTrue);
      });
    });

    group('autocomplete', () {
      late List<AutocompleteState> emitted;
      late TokenEditingController acController;

      setUp(() {
        emitted = [];
        acController = TokenEditingController(
          lexer: TokenLexer(rules: [_MentionRule()]),
          autocompleteTriggers: [
            const AutocompleteTrigger(
              triggerId: 'mention_search',
              activationMatcher: StartsWithMatcher('@'),
            ),
          ],
          onAutocompleteChange: emitted.add,
        );
      });

      tearDown(() {
        acController.dispose();
      });

      test('emits active state when trigger is typed', () {
        acController.value = const TextEditingValue(
          text: '@jo',
          selection: TextSelection.collapsed(offset: 3),
        );
        expect(emitted.last.isActive, isTrue);
        expect(emitted.last.activeTriggerId, 'mention_search');
        expect(emitted.last.query, 'jo');
      });

      test('emits inactive state when trigger word disappears', () {
        acController.value = const TextEditingValue(
          text: '@jo',
          selection: TextSelection.collapsed(offset: 3),
        );
        acController.value = const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
        expect(emitted.last.isActive, isFalse);
      });

      test('emits inactive state when selection is a non-collapsed range', () {
        acController.value = const TextEditingValue(
          text: '@jo',
          selection: TextSelection.collapsed(offset: 3),
        );
        // Select all — range selection should deactivate autocomplete.
        acController.value = const TextEditingValue(
          text: '@jo',
          selection: TextSelection(baseOffset: 0, extentOffset: 3),
        );
        expect(emitted.last.isActive, isFalse);
      });
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

  @override
  String toPlainText(TokenMatch match) => '@${match.groups[1]}';
}
