import 'package:flutter/material.dart';
import 'package:super_field/super_field.dart';

import '../rules/hashtag_rule.dart';
import '../widgets/demo_widgets.dart';

/// Demonstrates [StartsWithMatcher] with hashtag tokens:
///
/// - Words starting with `#` are highlighted as purple chips.
/// - Atomic deletion removes the entire chip with one backspace.
class HashtagScreen extends StatefulWidget {
  const HashtagScreen({super.key});

  @override
  State<HashtagScreen> createState() => _HashtagScreenState();
}

class _HashtagScreenState extends State<HashtagScreen> {
  late final TokenEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TokenEditingController(
      lexer: TokenLexer(rules: const [HashtagRule()]),
      text: 'Check out #flutter and #dart today!',
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
              title: 'Hashtag Tokens',
              description:
                  'Words beginning with # are matched by StartsWithMatcher '
                  'and rendered as purple badge chips. '
                  'Press backspace once on a hashtag to delete the whole token.',
            ),
            const SizedBox(height: 12),
            TokenizedTextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type a #hashtag…',
                labelText: 'Post',
              ),
              maxLines: 3,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            OutputCard(
              label: 'Raw text',
              value: _controller.text,
            ),
            const SizedBox(height: 8),
            OutputCard(
              label: 'Detected hashtags',
              value: _controller
                  .getMatchesByRule('hashtag')
                  .map((m) => m.fullText)
                  .join('  '),
            ),
          ],
        ),
      ),
    );
  }
}
