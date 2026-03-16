import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_field/super_field.dart';

void main() {
  group('TokenizedTextField', () {
    late TokenEditingController controller;

    setUp(() {
      controller = TokenEditingController(
        lexer: TokenLexer(rules: const [_MentionRule()]),
        text: '<@1|Alice>',
      );
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders mention label in editable mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TokenizedTextField(controller: controller),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);

      final editableText = tester.widget<EditableText>(find.byType(EditableText));
      final builtSpan = editableText.controller.buildTextSpan(
        context: tester.element(find.byType(EditableText)),
        style: editableText.style,
        withComposing: false,
      );
      expect(builtSpan.toPlainText(), '@Alice');
      final tokenSpan = _findTextSpanByText(builtSpan, '@Alice');
      expect(tokenSpan, isNotNull);
      expect(tokenSpan.style?.color, Colors.red);
    });

    testWidgets('renders mention label in read-only mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TokenizedTextField(
              controller: controller,
              readOnly: true,
            ),
          ),
        ),
      );

      expect(find.byType(SelectableText), findsOneWidget);

      final selectable = tester.widget<SelectableText>(find.byType(SelectableText));
      final span = selectable.textSpan!;
      expect(span.toPlainText(), '@Alice');
      final tokenSpan = _findTextSpanByText(span, '@Alice');
      expect(tokenSpan, isNotNull);
      expect(tokenSpan.style?.color, Colors.blue);
    });

    testWidgets('preserves composing range styling in editable mode', (
      tester,
    ) async {
      controller.value = const TextEditingValue(
        text: '<@1|Alice>',
        selection: TextSelection.collapsed(offset: 9),
        composing: TextRange(start: 1, end: 4),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TokenizedTextField(controller: controller),
          ),
        ),
      );

      final editableText = tester.widget<EditableText>(find.byType(EditableText));
      final builtSpan = editableText.controller.buildTextSpan(
        context: tester.element(find.byType(EditableText)),
        style: editableText.style,
        withComposing: true,
      );

      final composingSpan = _findTextSpan(
        builtSpan,
        (span) => span.style?.decoration == TextDecoration.underline,
      );
      expect(composingSpan, isNotNull);
    });

    testWidgets('supports focus and selection interaction in editable mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TokenizedTextField(controller: controller),
          ),
        ),
      );

      // Tap to focus the underlying EditableText.
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Move the selection around, including to the end of the raw text.
      expect(
        () {
          // Start of text.
          controller.selection = const TextSelection.collapsed(offset: 0);

          // Middle of text.
          final middleOffset = controller.text.length ~/ 2;
          controller.selection = TextSelection.collapsed(offset: middleOffset);

          // End of text.
          controller.selection =
              TextSelection.collapsed(offset: controller.text.length);

          // Move back to start again.
          controller.selection = const TextSelection.collapsed(offset: 0);
        },
        returnsNormally,
      );
    });
  });
}

TextSpan? _findTextSpanByText(InlineSpan span, String text) =>
    _findTextSpan(span, (candidate) => candidate.text == text);

TextSpan? _findTextSpan(InlineSpan span, bool Function(TextSpan) predicate) {
  if (span is TextSpan) {
    if (predicate(span)) {
      return span;
    }
    final children = span.children;
    if (children != null) {
      for (final child in children) {
        final found = _findTextSpan(child, predicate);
        if (found != null) return found;
      }
    }
  }
  return null;
}

class _MentionRule extends TokenRule {
  const _MentionRule();

  @override
  String get id => 'mention';

  @override
  TokenMatcher get matcher => MarkupMatcher(tagPrefix: '@');

  @override
  TokenBehavior get behavior => TokenBehavior.atomic;

  @override
  InlineSpan buildSpan({
    required BuildContext context,
    required TokenMatch match,
    required TextStyle defaultStyle,
    required bool isReadOnly,
  }) {
    final color = isReadOnly ? Colors.blue : Colors.red;
    return TextSpan(
      text: '@${match.groups[1]}',
      style: defaultStyle.copyWith(color: color),
    );
  }
}
