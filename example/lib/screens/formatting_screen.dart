import 'package:flutter/material.dart';
import 'package:super_field/super_field.dart';

import '../rules/formatting_rules.dart';
import '../widgets/demo_widgets.dart';

/// Demonstrates [SurroundedByMatcher] for inline text formatting:
///
/// - `**text**` renders as **bold**.
/// - `_text_` renders as _italic_.
/// - Both rules use `TokenBehavior.transparent` so the cursor can navigate
///   character-by-character inside the token.
class FormattingScreen extends StatefulWidget {
  const FormattingScreen({super.key});

  @override
  State<FormattingScreen> createState() => _FormattingScreenState();
}

class _FormattingScreenState extends State<FormattingScreen> {
  late final TokenEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TokenEditingController(
      lexer: TokenLexer(rules: const [BoldRule(), ItalicRule()]),
      text: 'This is **bold** and _italic_ text.',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
              title: 'Inline Formatting Tokens',
              description:
                  'SurroundedByMatcher wraps content between delimiters.\n'
                  '  **text** → bold   _text_ → italic\n'
                  'These tokens are transparent — the cursor navigates inside them normally.',
            ),
            const SizedBox(height: 12),
            TokenizedTextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Try **bold** or _italic_…',
                labelText: 'Formatted text',
              ),
              maxLines: 4,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            OutputCard(
              label: 'Plain text (getPlainText())',
              value: _controller.getPlainText(),
            ),
            const SizedBox(height: 8),
            OutputCard(
              label: 'Raw text (controller.text)',
              value: _controller.text,
            ),
          ],
        ),
      ),
    );
  }
}
