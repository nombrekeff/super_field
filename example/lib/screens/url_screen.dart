import 'package:flutter/material.dart';
import 'package:super_field/super_field.dart';

import '../rules/url_rule.dart';
import '../widgets/demo_widgets.dart';

/// Demonstrates [RegexMatcher] for URL detection:
///
/// - Any `http://` or `https://` URL in the text is highlighted in blue with
///   an underline.
/// - Detected URLs are listed below the field.
class UrlScreen extends StatefulWidget {
  const UrlScreen({super.key});

  @override
  State<UrlScreen> createState() => _UrlScreenState();
}

class _UrlScreenState extends State<UrlScreen> {
  late final TokenEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TokenEditingController(
      lexer: TokenLexer(rules: const [UrlRule()]),
      text: 'Visit https://flutter.dev or https://pub.dev for more info.',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = _controller.getMatchesByRule('url');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'URL Detection (RegexMatcher)',
              description:
                  'RegexMatcher finds all http/https URLs in the text and '
                  'renders them as blue underlined links. '
                  'The cursor navigates freely inside them (transparent behavior).',
            ),
            const SizedBox(height: 12),
            TokenizedTextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste a URL…',
                labelText: 'Message',
              ),
              maxLines: 3,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text(
              'Detected URLs (${urls.length})',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            if (urls.isEmpty)
              const Text('(none)', style: TextStyle(fontSize: 12))
            else
              ...urls.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.link,
                          size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          m.fullText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
