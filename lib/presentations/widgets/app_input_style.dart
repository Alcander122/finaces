import 'package:flutter/material.dart';

class AppInputStyle {
  static InputDecoration textField({
    required String label,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      suffixIcon: suffixIcon,
    );
  }

  static InputDecoration dropdown({
    required String label,
  }) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
