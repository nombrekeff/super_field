import 'package:flutter_test/flutter_test.dart';
import 'package:super_field/super_field.dart';

void main() {
  group('TokenMatch', () {
    test('equality', () {
      const a = TokenMatch(
        start: 0,
        end: 5,
        fullText: 'hello',
        groups: [],
        ruleId: 'test',
      );
      const b = TokenMatch(
        start: 0,
        end: 5,
        fullText: 'hello',
        groups: [],
        ruleId: 'test',
      );
      expect(a, equals(b));
    });
  });

  group('RegexMatcher', () {
    test('matches simple pattern', () {
      final matcher = RegexMatcher(RegExp(r'#\w+'));
      final matches = matcher.findMatches('Hello #world, #dart!', 'tag').toList();
      expect(matches.length, 2);
      expect(matches[0].fullText, '#world');
      expect(matches[1].fullText, '#dart');
    });

    test('captures groups', () {
      final matcher = RegexMatcher(RegExp(r'(\w+)=(\w+)'));
      final matches =
          matcher.findMatches('key=value', 'kv').toList();
      expect(matches.first.groups, ['key', 'value']);
    });

    test('returns empty for no match', () {
      final matcher = RegexMatcher(RegExp(r'@\w+'));
      expect(matcher.findMatches('no mentions here', 'mention'), isEmpty);
    });
  });

  group('StartsWithMatcher', () {
    test('matches trigger word', () {
      final matcher = StartsWithMatcher('@');
      final matches = matcher.findMatches('Hello @john today', 'mention').toList();
      expect(matches.length, 1);
      expect(matches[0].fullText, '@john');
      expect(matches[0].groups, ['john']);
    });

    test('matches multiple triggers', () {
      final matcher = StartsWithMatcher('@');
      final matches =
          matcher.findMatches('@alice and @bob', 'mention').toList();
      expect(matches.length, 2);
    });

    test('does not match trigger without content', () {
      final matcher = StartsWithMatcher('@');
      final matches = matcher.findMatches('hello @ world', 'mention').toList();
      expect(matches, isEmpty);
    });
  });

  group('SurroundedByMatcher', () {
    test('matches single token', () {
      final matcher =
          SurroundedByMatcher(prefix: '**', suffix: '**');
      final matches =
          matcher.findMatches('This is **bold** text', 'bold').toList();
      expect(matches.length, 1);
      expect(matches[0].fullText, '**bold**');
      expect(matches[0].groups, ['bold']);
    });

    test('matches multiple tokens', () {
      final matcher =
          SurroundedByMatcher(prefix: '[', suffix: ']');
      final matches =
          matcher.findMatches('[one] and [two]', 'bracket').toList();
      expect(matches.length, 2);
    });

    test('returns empty when no match', () {
      final matcher =
          SurroundedByMatcher(prefix: '(', suffix: ')');
      expect(matcher.findMatches('no parens', 'p'), isEmpty);
    });
  });

  group('MarkupMatcher', () {
    test('extracts id and label', () {
      final matcher = MarkupMatcher(tagPrefix: '@');
      final matches =
          matcher.findMatches('Hi <@123|John Doe>!', 'mention').toList();
      expect(matches.length, 1);
      expect(matches[0].fullText, '<@123|John Doe>');
      expect(matches[0].groups, ['123', 'John Doe']);
      expect(matches[0].start, 3);
      expect(matches[0].end, 18);
    });

    test('handles multiple tokens', () {
      final matcher = MarkupMatcher(tagPrefix: '@');
      final text = '<@1|Alice> and <@2|Bob>';
      final matches = matcher.findMatches(text, 'mention').toList();
      expect(matches.length, 2);
      expect(matches[0].groups[1], 'Alice');
      expect(matches[1].groups[1], 'Bob');
    });

    test('does not match wrong prefix', () {
      final matcher = MarkupMatcher(tagPrefix: '@');
      expect(matcher.findMatches('<#channel|general>', 'mention'), isEmpty);
    });
  });

  group('TokenLexer', () {
    _MockMentionRule buildRule() => _MockMentionRule();

    test('returns empty list for empty string', () {
      final lexer = TokenLexer(rules: [buildRule()]);
      expect(lexer.parse(''), isEmpty);
    });

    test('parses single token', () {
      final lexer = TokenLexer(rules: [buildRule()]);
      final ast = lexer.parse('Hello <@1|John>!');
      expect(ast.length, 1);
      expect(ast[0].ruleId, 'mention');
    });

    test('first rule wins on overlap', () {
      final highPriority = _MockBoldRule();
      final lowPriority = _MockMentionRule();
      final lexer = TokenLexer(rules: [highPriority, lowPriority]);

      // Both rules match the same range — highPriority should win.
      final ast = lexer.parse('**text**');
      expect(ast.length, 1);
      expect(ast[0].ruleId, 'bold');
    });

    test('results are ordered by position', () {
      final lexer = TokenLexer(rules: [buildRule()]);
      final ast = lexer.parse('<@2|Bob> and <@1|Alice>');
      expect(ast[0].groups[1], 'Bob');
      expect(ast[1].groups[1], 'Alice');
    });

    test('toPlainText defaults to fullText for rules that do not override it', () {
      // _MockBoldRule does not override toPlainText, so it falls back to fullText.
      final lexer = TokenLexer(rules: [_MockBoldRule()]);
      final ast = lexer.parse('This is **bold** text');
      expect(ast.length, 1);
      final rule = _MockBoldRule();
      expect(rule.toPlainText(ast[0]), ast[0].fullText);
    });
  });
}

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _MockMentionRule extends TokenRule {
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

class _MockBoldRule extends TokenRule {
  @override
  String get id => 'bold';

  @override
  TokenMatcher get matcher =>
      SurroundedByMatcher(prefix: '**', suffix: '**');

  @override
  TokenBehavior get behavior => TokenBehavior.transparent;

  @override
  InlineSpan buildSpan({
    required context,
    required match,
    required defaultStyle,
    required isReadOnly,
  }) =>
      TextSpan(text: match.groups[0]);
}
