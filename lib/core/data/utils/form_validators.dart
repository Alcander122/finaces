// utils/form_validators.dart
import 'package:finances/core/errors/error_strings.dart';

class FormValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return ErrorStrings.requiredField;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return ErrorStrings.invalidEmail;
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return ErrorStrings.requiredField;
    if (value.length < 6) return "Mínimo 6 caracteres";
    return null;
  }
}
