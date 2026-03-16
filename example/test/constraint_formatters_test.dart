import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_field/super_field.dart';
import 'package:super_field_example/formatters/constraint_formatters.dart';
import 'package:super_field_example/rules/mention_rule.dart';

void main() {
  group('SingleTokenOnlyFormatter', () {
    const formatter = SingleTokenOnlyFormatter(
      lexer: TokenLexer(rules: [MentionRule()]),
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

    test('allows typing standalone @ as in-progress mention input', () {
      final result = apply(oldText: '', newText: '@', cursorOffset: 1);
      expect(result.text, '@');
    });

    test('allows typing @query as in-progress mention input', () {
      final result = apply(oldText: '@', newText: '@al', cursorOffset: 3);
      expect(result.text, '@al');
    });

    test('rejects plain text that is not a mention token', () {
      final result = apply(oldText: '', newText: 'alice', cursorOffset: 5);
      expect(result.text, '');
    });

    test('accepts a single completed mention token', () {
      const token = '<@1|Alice Johnson>';
      final result = apply(oldText: '@al', newText: token, cursorOffset: token.length);
      expect(result.text, token);
    });
  });
}
