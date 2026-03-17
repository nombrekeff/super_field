import 'package:flutter/widgets.dart';
import 'package:super_field/super_field.dart';

class AutocompleteConfig {
  const AutocompleteConfig({
    this.triggers = const [],
    this.onChange,
    this.onSelect,
    this.onGetSuggestions,
    this.suggestionItemBuilder,
  });

  static const defaultConfig = AutocompleteConfig();

  /// Optional autocomplete triggers evaluated after every text change.
  final List<AutocompleteTrigger> triggers;

  /// Callback invoked whenever the [AutocompleteState] changes.
  final ValueChanged<AutocompleteState>? onChange;

  final ValueChanged<dynamic>? onSelect;

  /// Function that returns a list of suggestions based on the current autocomplete state.
  /// Typically used to feed data into an autocomplete overlay.
  final List<dynamic> Function(AutocompleteState state)? onGetSuggestions;

  /// Optional builder for rendering suggestion items in the autocomplete overlay.
  final Widget Function(BuildContext context, dynamic suggestion)?
      suggestionItemBuilder;
}
