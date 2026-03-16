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
      expect(find.text('@Alice'), findsOneWidget);
      expect(find.text('<@1|Alice>'), findsNothing);

      final editableText = tester.widget<EditableText>(find.byType(EditableText));
      final builtSpan = editableText.controller.buildTextSpan(
        context: tester.element(find.byType(EditableText)),
        style: editableText.style,
        withComposing: false,
      );
      final tokenSpan = builtSpan.children!.single as TextSpan;
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
      expect(find.text('@Alice'), findsOneWidget);
      expect(find.text('<@1|Alice>'), findsNothing);

      final selectable = tester.widget<SelectableText>(find.byType(SelectableText));
      final tokenSpan = selectable.textSpan!.children!.single as TextSpan;
      expect(tokenSpan.style?.color, Colors.blue);
    });
  });
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
