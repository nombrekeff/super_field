import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_field/super_field.dart';
import 'package:super_field_example/rules/mention_rule.dart';

void main() {
  group('MentionRule', () {
    const rule = MentionRule();
    const match = TokenMatch(
      start: 0,
      end: 10,
      fullText: '<@1|Alice>',
      groups: ['1', 'Alice'],
      ruleId: 'mention',
    );
    const baseStyle = TextStyle(fontSize: 14);

    testWidgets('renders compact chip while editable', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      final span = rule.buildSpan(
        context: context,
        match: match,
        defaultStyle: baseStyle,
        isReadOnly: false,
      );

      expect(span, isA<WidgetSpan>());
      final widgetSpan = span as WidgetSpan;

      final outerPadding = widgetSpan.child as Padding;
      expect(
        outerPadding.padding,
        const EdgeInsets.symmetric(horizontal: 2),
      );

      final chip = outerPadding.child as Chip;
      expect(chip.materialTapTargetSize, MaterialTapTargetSize.shrinkWrap);
      expect(chip.visualDensity,
          const VisualDensity(horizontal: -4, vertical: -4));
      expect(chip.labelPadding, EdgeInsets.zero);
      expect(chip.padding, EdgeInsets.zero);
      expect(chip.labelStyle?.fontSize, 12);
      expect(chip.labelStyle?.height, 1);
    });

    testWidgets('renders bold teal text while read-only', (tester) async {
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
      expect(textSpan.text, '@Alice');
      expect(textSpan.style?.color, Colors.teal);
      expect(textSpan.style?.fontWeight, FontWeight.bold);
    });
  });
}
