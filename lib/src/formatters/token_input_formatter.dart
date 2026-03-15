import 'package:flutter/services.dart';

import '../lexer/token_lexer.dart';
import '../lexer/token_match.dart';

/// Base class for formatters that have access to the parsed AST of the
/// incoming text.
///
/// Extend this class instead of [TextInputFormatter] when your formatting
/// logic needs to reason about token positions (e.g., blocking edits inside
/// a token or transforming token syntax).
abstract class TokenInputFormatter extends TextInputFormatter {
  const TokenInputFormatter({required this.lexer});

  /// The lexer used to parse the incoming text before [formatAst] is called.
  final TokenLexer lexer;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newAst = lexer.parse(newValue.text);
    return formatAst(oldValue, newValue, newAst);
  }

  /// Override to apply formatting logic using the pre-parsed [ast].
  ///
  /// Return the desired [TextEditingValue] (which may be unchanged).
  TextEditingValue formatAst(
    TextEditingValue oldValue,
    TextEditingValue newValue,
    List<TokenMatch> ast,
  );
}
