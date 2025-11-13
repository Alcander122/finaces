// core/data/utils/form_validator.dart
class FormValidator {
  /// Valida monto con formato colombiano: "$ 1.234.567,89"
  String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un monto';
    }

    // LIMPIAR FORMATO: "$ 1.234.567,89" → "1234567.89"
    final cleaned = _cleanCurrencyFormat(value);
    final num = double.tryParse(cleaned);

    if (num == null) {
      return 'Ingrese un número válido';
    }
    if (num <= 0) {
      return 'El monto debe ser mayor a 0';
    }
    return null;
  }

  /// Valida descripción (requerida)
  String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese una descripción';
    }
    if (value.trim().length < 3) {
      return 'La descripción debe tener al menos 3 caracteres';
    }
    return null;
  }

  /// Valida campo requerido genérico
  String? validateRequired(String? value, String field) {
    if (value?.trim().isEmpty == true) {
      return 'El campo $field es obligatorio';
    }
    return null;
  }

  /// Limpia formato de moneda colombiana
  /// "$ 1.234.567,89" → "1234567.89"
  String _cleanCurrencyFormat(String value) {
    return value
        .replaceAll(RegExp(r'[^\d,]'), '') // Quita $, espacios, letras
        .replaceAll('.', '') // Quita puntos de miles
        .replaceAll(',', '.') // Coma → punto decimal
        .trim();
  }
}
