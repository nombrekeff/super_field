import 'package:flutter/material.dart';

import '../controller/token_editing_controller.dart';
import 'tokenized_text_field.dart';

/// A [FormField] wrapper around [TokenizedTextField].
///
/// Enables seamless integration with Flutter's [Form] widget:
/// `Form.of(context).validate()`, [validator], and [onSaved] all work as
/// expected.
///
/// Autocomplete triggers and callbacks are configured directly on the
/// [TokenEditingController]. The form field value is initialized from
/// [controller.text]; do **not** also pass [initialValue] as the controller
/// already carries the initial text.
class TokenizedTextFormField extends FormField<String> {
  /// Creates a [TokenizedTextFormField].
  ///
  /// The [controller] is required. All other parameters mirror
  /// [TokenizedTextField] or standard [FormField] properties.
  TokenizedTextFormField({
    super.key,
    required TokenEditingController controller,
    bool readOnly = false,
    InputDecoration? decoration,
    TextStyle? style,
    int? maxLines = 1,
    FocusNode? focusNode,
    ValueChanged<String>? onChanged,
    // FormField properties
    super.validator,
    super.onSaved,
    super.autovalidateMode,
    super.enabled,
    super.restorationId,
  }) : super(
          // Seed the FormField value from the controller's current text so
          // that validation and onSaved always see an up-to-date value even
          // before the user types anything.
          initialValue: controller.text,
          builder: (FormFieldState<String> field) {
            void onChangedHandler(String value) {
              field.didChange(value);
              onChanged?.call(value);
            }

            return TokenizedTextField(
              controller: controller,
              readOnly: readOnly,
              decoration: decoration?.copyWith(
                errorText: field.errorText ?? decoration.errorText,
              ) ??
                  (field.errorText != null
                      ? InputDecoration(errorText: field.errorText)
                      : null),
              style: style,
              maxLines: maxLines,
              focusNode: focusNode,
              onChanged: onChangedHandler,
            );
          },
        );
}
