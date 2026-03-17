import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_field/super_field.dart';

class Autocompletable extends StatefulWidget {
  const Autocompletable({
    super.key,
    required this.child,
    required this.controller,
  });

  final Widget child;
  final TokenEditingController controller;

  @override
  AutocompletableState createState() => AutocompletableState();
}

class AutocompletableState extends State<Autocompletable> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant Autocompletable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _onControllerChanged();
    }
  }

  void _onControllerChanged() {
    final autocomplete = widget.controller.autocompleteState;
    final suggestions =
        widget.controller.autocomplete.onGetSuggestions?.call(autocomplete) ?? [];

    if (suggestions.isEmpty) {
      selectedIndex = 0;
    } else if (selectedIndex >= suggestions.length) {
      selectedIndex = suggestions.length - 1;
    }

    setState(() {});
  }

  void setSelectedIndex(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  KeyEventResult handleKeyboardEvent(FocusNode node, KeyEvent event) {
    final autocomplete = widget.controller.autocompleteState;
    final suggestions =
        widget.controller.autocomplete.onGetSuggestions?.call(autocomplete) ?? [];

    if (autocomplete.isActive && suggestions.isNotEmpty && event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setSelectedIndex((selectedIndex + 1) % suggestions.length);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setSelectedIndex((selectedIndex - 1 + suggestions.length) % suggestions.length);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _selectSuggestion(suggestions[selectedIndex]);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _selectSuggestion(dynamic suggestion) {
    widget.controller.autocomplete.onSelect?.call(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final autocomplete = widget.controller.autocompleteState;
    final suggestions =
        widget.controller.autocomplete.onGetSuggestions?.call(autocomplete) ?? [];

    return Focus(
      canRequestFocus: false,
      onKeyEvent: handleKeyboardEvent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            widget.child,
            if (autocomplete.isActive && suggestions.isNotEmpty)
              SuggestionList(
                suggestions: suggestions,
                itemBuilder: (context, suggestion) {
                  return widget.controller.autocomplete.suggestionItemBuilder
                          ?.call(context, suggestion) ??
                      const SizedBox.shrink();
                },
                onSelect: _selectSuggestion,
                selectedIndex: selectedIndex,
              ),
          ],
        ),
      ),
    );
  }
}

class SuggestionList extends StatefulWidget {
  const SuggestionList({
    super.key,
    required this.suggestions,
    required this.itemBuilder,
    this.onSelect,
    this.selectedIndex = 0,
  });

  // TODO: Make more configurable (e.g., support sections, empty state, custom item builder, etc.)
  // TODO: Allow styling to be inherited from the app theme (e.g., use ListTileTheme) instead of hardcoding it here or passing it manually.

  final List<dynamic> suggestions;
  final Widget Function(BuildContext context, dynamic suggestion) itemBuilder;
  final ValueChanged<dynamic>? onSelect;

  final int selectedIndex;

  @override
  State<SuggestionList> createState() => _SuggestionListState();
}

class _SuggestionListState extends State<SuggestionList> {
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: Theme.of(context).cardTheme.elevation ?? 4,
      borderRadius: BorderRadius.circular(8),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: widget.suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          return Material(
            color: i == widget.selectedIndex ? Colors.grey.shade300 : null,
            child: InkWell(
              canRequestFocus: false,
              onTap: () => widget.onSelect?.call(widget.suggestions[i]),
              child: widget.itemBuilder(context, widget.suggestions[i]),
            ),
          );
        },
      ),
    );
  }
}
