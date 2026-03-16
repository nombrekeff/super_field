# super_field

A lightweight, highly extensible Flutter text editing ecosystem that bridges the gap between a standard `TextField` and complex document editors.

`super_field` lets you embed interactive, data-backed UI components — mention chips, colour badges, dynamic tags — directly into the text flow while guaranteeing flawless native cursor navigation, hardware keyboard support, and atomic deletion.

---

## Features

- **Lexing Engine** — A flat AST parser driven by composable `TokenRule` definitions.
- **Built-in Matchers** — `RegexMatcher`, `StartsWithMatcher`, `SurroundedByMatcher`, `MarkupMatcher`.
- **Cursor Guard** — `TokenEditingController` intercepts every cursor movement and prevents the caret from landing inside hidden markup.
- **Atomic Deletion** — `AtomicDeletionFormatter` removes an entire token on a single backspace press.
- **Autocomplete** — State-driven trigger management; the package emits `AutocompleteState` events, and you supply the UI.
- **Form Support** — `TokenizedTextFormField` integrates with Flutter's `Form` / `validator` / `onSaved` API.
- **Read-only mode** — Pass `readOnly: true` to render a selectable, non-editable rich-text view.
- **Mobile IME protection** — `autocorrect: false` and `enableSuggestions: false` are always enforced.

---

## Getting started

```yaml
dependencies:
  super_field: ^0.1.0
```

---

## Quick start

### 1. Define a rule

```dart
class MentionRule extends TokenRule {
  @override
  String get id => 'mention';

  @override
  TokenMatcher get matcher => MarkupMatcher(tagPrefix: '@');

  @override
  TokenBehavior get behavior => TokenBehavior.atomic;

  @override
  InlineSpan buildSpan({
    required BuildContext context,
    required TokenMatch match,
    required TextStyle defaultStyle,
    required bool isReadOnly,
  }) {
    return WidgetSpan(
      child: Chip(label: Text('@${match.groups[1]}')),
    );
  }

  @override
  String toPlainText(TokenMatch match) => '@${match.groups[1]}';
}
```

### 2. Create a controller

```dart
final controller = TokenEditingController(
  lexer: TokenLexer(rules: [MentionRule()]),
  autocompleteTriggers: [
    AutocompleteTrigger(
      triggerId: 'mention_search',
      activationMatcher: StartsWithMatcher('@'),
    ),
  ],
  onAutocompleteChange: (state) {
    // Show / hide your autocomplete UI here
  },
);
```

### 3. Use the widget

```dart
TokenizedTextField(
  controller: controller,
  decoration: const InputDecoration(hintText: 'Type @ to mention someone…'),
  inputFormatters: const [
    // Add custom constraints, e.g. single-token-only fields.
  ],
)
```

### 4. Insert a completed token

```dart
controller.replaceMatch(
  state.matchBounds!,         // the "@jo" range
  '<@123|John Doe> ',         // the fully-formed markup token
);
```

---

## Hidden markup syntax

The raw string stored by the controller may contain hidden markup. Use the `MarkupMatcher` to work with the `<[prefix][id]|[label]>` pattern.

| Raw string | Rendered |
|---|---|
| `Hello <@123|John Doe>!` | `Hello` **@John Doe** `!` |

When you need to persist the value, call `controller.text` to get the full raw string. To get a human-readable version, call `controller.getPlainText()`.

---

## Architecture overview

```
TokenRule (id, matcher, behavior, buildSpan, toPlainText)
    │
    ▼
TokenLexer.parse(text) → List<TokenMatch>   ← flat AST
    │
    ▼
TokenEditingController
    ├── set value → _sanitizeSelection (cursor guard)
    ├── getMatchesByRule(ruleId)
    ├── getPlainText()
    └── replaceMatch(match, replacement)

TokenizedTextField
    ├── AtomicDeletionFormatter   (mandatory)
    ├── inputFormatters           (optional custom constraints)
    ├── autocorrect: false
    └── enableSuggestions: false

TokenizedTextFormField   (wraps TokenizedTextField as a FormField)
```

---

## Token matchers

| Matcher | Use case |
|---|---|
| `RegexMatcher(pattern)` | Any regex-based token |
| `StartsWithMatcher(trigger)` | `@mention`, `#hashtag`, etc. |
| `SurroundedByMatcher(prefix, suffix)` | `**bold**`, `[link]`, etc. |
| `MarkupMatcher(tagPrefix)` | Hidden-ID markup `<@123|Label>` |

---

## Example app scenarios

The `example/` app includes ready-to-run demos for common constraints:

- Mention autocomplete with markup tokens
- Single-value token fields (single mention, single hashtag)
- Token-list-only fields (hashtags separated by spaces only)

---

## License

MIT
