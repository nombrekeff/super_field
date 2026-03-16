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
    return TextSpan(text: '@${match.groups[1]}', style: defaultStyle);
  }
}
