import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_field/super_field.dart';
import 'package:super_field_example/rules/hashtag_rule.dart';

void main() {
  group('HashtagRule', () {
    const rule = HashtagRule();
    const match = TokenMatch(
      start: 0,
      end: 8,
      fullText: '#flutter',
      groups: ['flutter'],
      ruleId: 'hashtag',
    );
    const baseStyle = TextStyle(fontSize: 14);

    test('is transparent to allow editing inside hashtag text', () {
      expect(rule.behavior, TokenBehavior.transparent);
    });

    testWidgets('renders purple TextSpan while editable', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      final span = rule.buildSpan(
        context: context,
        match: match,
        defaultStyle: baseStyle,
        isReadOnly: false,
      );

      expect(span, isA<TextSpan>());
      final textSpan = span as TextSpan;
      expect(textSpan.text, '#flutter');
      expect(textSpan.style?.color, Colors.deepPurple);
    });

    testWidgets('renders purple TextSpan while read-only', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      final span = rule.buildSpan(
        context: context,
        match: match,
        defaultStyle: baseStyle,
        isReadOnly: true,
      );

      expect(span, isA<TextSpan>());
      final textSpan = span as TextSpan;
      expect(textSpan.text, '#flutter');
      expect(textSpan.style?.color, Colors.deepPurple);
    });
  });
}
