import 'package:flutter/material.dart';
import 'package:super_field/super_field.dart';

import '../rules/mention_rule.dart';
import '../rules/hashtag_rule.dart';
import '../widgets/demo_widgets.dart';

/// Demonstrates [TokenizedTextFormField] integrated with Flutter's [Form]:
///
/// - Standard `validator` rejects empty submissions.
/// - `onSaved` captures the plain-text value on form save.
/// - Uses both mention and hashtag rules simultaneously.
class FormFieldScreen extends StatefulWidget {
  const FormFieldScreen({super.key});

  @override
  State<FormFieldScreen> createState() => _FormFieldScreenState();
}

class _FormFieldScreenState extends State<FormFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TokenEditingController _controller;
  String? _savedValue;

  @override
  void initState() {
    super.initState();
    _controller = TokenEditingController(
      lexer: TokenLexer(rules: const [MentionRule(), HashtagRule()]),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
    }
  }

  void _reset() {
    _formKey.currentState?.reset();
    _controller.clear();
    setState(() => _savedValue = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Form Field Integration',
                description:
                    'TokenizedTextFormField wraps TokenizedTextField as a '
                    'standard Flutter FormField, giving you validator, onSaved, '
                    'and autovalidateMode support out of the box.',
              ),
              const SizedBox(height: 12),
              TokenizedTextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Write your post (@ for mention, # for tag)…',
                  labelText: 'Post content',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Post content cannot be empty.';
                  }
                  return null;
                },
                onSaved: (value) {
                  setState(() {
                    // Store the plain-text version on save.
                    _savedValue = _controller.getPlainText();
                  });
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Submit'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _reset,
                    child: const Text('Reset'),
                  ),
                ],
              ),
              if (_savedValue != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                OutputCard(
                  label: 'Saved plain-text value',
                  value: _savedValue!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
