import 'package:flutter/material.dart';
import 'package:super_field/super_field.dart';

import '../rules/mention_rule.dart';
import '../rules/hashtag_rule.dart';
import '../rules/url_rule.dart';
import '../rules/formatting_rules.dart';
import '../widgets/demo_widgets.dart';

/// Demonstrates the read-only mode of [TokenizedTextField]:
///
/// - `readOnly: true` renders a selectable, non-editable rich-text view.
/// - Rules can provide different visual representations for read-only mode
///   (e.g., flat coloured text instead of interactive chips).
class ReadOnlyScreen extends StatefulWidget {
  const ReadOnlyScreen({super.key});

  @override
  State<ReadOnlyScreen> createState() => _ReadOnlyScreenState();
}

class _ReadOnlyScreenState extends State<ReadOnlyScreen> {
  late final TokenEditingController _readOnlyController;

  @override
  void initState() {
    super.initState();
    _readOnlyController = TokenEditingController(
      lexer: TokenLexer(
        rules: const [
          MentionRule(),
          HashtagRule(),
          UrlRule(),
          BoldRule(),
          ItalicRule(),
        ],
      ),
      text: 'Hello <@1|Alice Johnson> and <@2|Bob Smith>! '
          'Check out #flutter at https://flutter.dev — **amazing** framework!',
    );
  }

  @override
  void dispose() {
    _readOnlyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Read-only Mode',
              description:
                  'Pass readOnly: true to render a selectable, non-editable '
                  'rich-text display. Rules can render differently in read-only '
                  'mode — mentions become coloured bold text instead of chips.',
            ),
            const SizedBox(height: 12),
            TokenizedTextField(
              controller: _readOnlyController,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Read-only view',
                filled: true,
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            const SectionHeader(
              title: 'All rules combined (editable)',
              description:
                  'The same rules work together in an editable field. '
                  'You can mix mentions, hashtags, URLs, and formatting.',
            ),
            const SizedBox(height: 12),
            const _CombinedField(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Combined editable demo
// ---------------------------------------------------------------------------

class _CombinedField extends StatefulWidget {
  const _CombinedField();

  @override
  State<_CombinedField> createState() => _CombinedFieldState();
}

class _CombinedFieldState extends State<_CombinedField> {
  late final TokenEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TokenEditingController(
      lexer: TokenLexer(
        rules: const [
          MentionRule(),
          HashtagRule(),
          UrlRule(),
          BoldRule(),
          ItalicRule(),
        ],
      ),
      text: 'Try editing: <@1|Alice Johnson> loves #flutter at https://flutter.dev',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TokenizedTextField(
      controller: _controller,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Edit me…',
        labelText: 'Combined field',
      ),
      maxLines: 3,
      onChanged: (_) => setState(() {}),
    );
  }
}
