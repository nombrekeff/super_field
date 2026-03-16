import 'package:flutter/material.dart';
import 'package:super_field/super_field.dart';

import '../formatters/constraint_formatters.dart';
import '../rules/mention_rule.dart';
import '../widgets/demo_widgets.dart';

// ---------------------------------------------------------------------------
// Fake user database used for autocomplete suggestions
// ---------------------------------------------------------------------------

const _users = [
  {'id': '1', 'name': 'Alice Johnson'},
  {'id': '2', 'name': 'Bob Smith'},
  {'id': '3', 'name': 'Carol White'},
  {'id': '4', 'name': 'David Lee'},
  {'id': '5', 'name': 'Eve Martinez'},
];

/// Demonstrates [MarkupMatcher] with autocomplete:
///
/// - Type `@` followed by a name fragment to trigger the suggestion overlay.
/// - Tap a suggestion to insert the fully-formed `<@id|Name>` markup token.
/// - The field shows a chip for each mention.
/// - "Plain text" output strips hidden markup to a human-readable string.
class MentionScreen extends StatefulWidget {
  const MentionScreen({super.key});

  @override
  State<MentionScreen> createState() => _MentionScreenState();
}

class _MentionScreenState extends State<MentionScreen> {
  late final TokenEditingController _controller;
  late final TokenEditingController _singleController;
  AutocompleteState _autocomplete = AutocompleteState.inactive;
  AutocompleteState _singleAutocomplete = AutocompleteState.inactive;

  @override
  void initState() {
    super.initState();
    _controller = TokenEditingController(
      lexer: const TokenLexer(rules: [MentionRule()]),
      autocompleteTriggers: [
        const AutocompleteTrigger(
          triggerId: 'mention_search',
          activationMatcher: StartsWithMatcher('@'),
        ),
      ],
      onAutocompleteChange: (state) {
        setState(() => _autocomplete = state);
      },
    );
    _singleController = TokenEditingController(
      lexer: const TokenLexer(rules: [MentionRule()]),
      autocompleteTriggers: [
        const AutocompleteTrigger(
          triggerId: 'mention_search_single',
          activationMatcher: StartsWithMatcher('@'),
        ),
      ],
      onAutocompleteChange: (state) {
        setState(() => _singleAutocomplete = state);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _singleController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _suggestions {
    if (!_autocomplete.isActive) return [];
    final query = (_autocomplete.query ?? '').toLowerCase();
    return _users
        .where((u) => u['name']!.toLowerCase().contains(query))
        .toList();
  }

  List<Map<String, String>> get _singleSuggestions {
    if (!_singleAutocomplete.isActive) return [];
    final query = (_singleAutocomplete.query ?? '').toLowerCase();
    return _users
        .where((u) => u['name']!.toLowerCase().contains(query))
        .toList();
  }

  void _insertMention(Map<String, String> user) {
    final bounds = _autocomplete.matchBounds;
    if (bounds == null) return;
    _controller.replaceMatch(bounds, '<@${user['id']}|${user['name']}> ');
    setState(() => _autocomplete = AutocompleteState.inactive);
  }

  void _insertSingleMention(Map<String, String> user) {
    final bounds = _singleAutocomplete.matchBounds;
    if (bounds == null) return;
    _singleController.replaceMatch(bounds, '<@${user['id']}|${user['name']}>');
    setState(() => _singleAutocomplete = AutocompleteState.inactive);
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
                title: 'Mention Tokens',
                description:
                    'Type @ followed by a name to trigger autocomplete. '
                    'Mentions use the hidden markup syntax <@id|Label> '
                    'and render as chips. A single backspace deletes the '
                    'entire chip (atomic deletion).',
              ),
              const SizedBox(height: 12),
              TokenizedTextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type @ to mention someone…',
                  labelText: 'Message',
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_autocomplete.isActive && _suggestions.isNotEmpty) ...[
                const SizedBox(height: 4),
                _SuggestionList(
                  suggestions: _suggestions,
                  onSelect: _insertMention,
                ),
              ],
              const SizedBox(height: 16),
              OutputCard(
                label: 'Raw text (controller.text)',
                value: _controller.text,
              ),
              const SizedBox(height: 8),
              OutputCard(
                label: 'Plain text (controller.getPlainText())',
                value: _controller.getPlainText(),
              ),
              const SizedBox(height: 8),
              OutputCard(
                label: 'Parsed mentions',
                value: _controller
                    .getMatchesByRule('mention')
                    .map((m) => '${m.groups[1]} (id=${m.groups[0]})')
                    .join(', '),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Single Mention Field',
                description:
                    'This field accepts only one mention token. Try typing @ '
                    'and selecting a user. Adding regular text or multiple '
                    'mentions is blocked by an input formatter.',
              ),
              const SizedBox(height: 12),
              TokenizedTextFormField(
                controller: _singleController,
                inputFormatters: const [
                  SingleTokenOnlyFormatter(
                    lexer: TokenLexer(rules: [MentionRule()]),
                    ruleId: 'mention',
                  ),
                ],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type @ and choose one user…',
                  labelText: 'Assignee',
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_singleAutocomplete.isActive &&
                  _singleSuggestions.isNotEmpty) ...[
                const SizedBox(height: 4),
                _SuggestionList(
                  suggestions: _singleSuggestions,
                  onSelect: _insertSingleMention,
                ),
              ],
              const SizedBox(height: 8),
              OutputCard(
                label: 'Single mention plain text',
                value: _singleController.getPlainText(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Suggestion list overlay
// ---------------------------------------------------------------------------

class _SuggestionList extends StatelessWidget {
  final List<Map<String, String>> suggestions;
  final ValueChanged<Map<String, String>> onSelect;

  const _SuggestionList({
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final user = suggestions[i];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.teal.shade200,
              child: Text(
                user['name']![0],
                style: const TextStyle(fontSize: 12),
              ),
            ),
            title: Text(user['name']!),
            onTap: () => onSelect(user),
          );
        },
      ),
    );
  }
}
