import 'package:flutter/material.dart';
import 'package:super_field/super_field.dart';

import '../formatters/constraint_formatters.dart';
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
  late final TokenEditingController _singleHashtagController;
  late final TokenEditingController _hashtagListController;

  @override
  void initState() {
    super.initState();
    _controller = TokenEditingController(
      lexer: const TokenLexer(rules: [HashtagRule()]),
      text: 'Check out #flutter and #dart today!',
    );
    _singleHashtagController = TokenEditingController(
      lexer: const TokenLexer(rules: [HashtagRule()]),
      text: '#flutter',
    );
    _hashtagListController = TokenEditingController(
      lexer: const TokenLexer(rules: [HashtagRule()]),
      text: '#flutter #dart',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _singleHashtagController.dispose();
    _hashtagListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
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
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Single Hashtag Field',
                description:
                    'This field demonstrates single-value constraints: only one '
                    'hashtag token is accepted and extra typing is blocked.',
              ),
              const SizedBox(height: 12),
              TokenizedTextFormField(
                controller: _singleHashtagController,
                inputFormatters: const [
                  SingleTokenOnlyFormatter(
                    lexer: TokenLexer(rules: [HashtagRule()]),
                    ruleId: 'hashtag',
                  ),
                ],
                decoration: const InputDecoration(
<<<<<<< copilot/fix-atomic-token-deletion
                  border: OutlineInputBorder(),
=======
                  border: const OutlineInputBorder(),
>>>>>>> main
                  hintText: 'Example: #flutter',
                  labelText: 'Primary hashtag',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              const SectionHeader(
                title: 'Hashtag List-Only Field',
                description:
                    'This field accepts only a list of hashtags separated by '
                    'spaces (for example: #flutter #dart #ui). Invalid typing '
                    'is blocked by an input formatter.',
              ),
              const SizedBox(height: 12),
              TokenizedTextFormField(
                controller: _hashtagListController,
                maxLines: 2,
                inputFormatters: const [
                  HashtagListOnlyFormatter(
                    lexer: TokenLexer(rules: [HashtagRule()]),
                    ruleId: 'hashtag',
                  ),
                ],
                decoration: const InputDecoration(
<<<<<<< copilot/fix-atomic-token-deletion
                  border: OutlineInputBorder(),
=======
                  border: const OutlineInputBorder(),
>>>>>>> main
                  hintText: '#flutter #dart #mobile',
                  labelText: 'Allowed tags',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
