// core/data/utils/form_validator.dart
class FormValidator {
  String? validateAmount(String? value) {
    if (value == null || value.isEmpty) return 'Por favor ingrese un monto';
    final num = double.tryParse(value);
    if (num == null) return 'Ingrese un número válido';
    if (num <= 0) return 'El monto debe ser mayor a 0';
    return null;
  }

  String? validateDescription(String? value) {
    if (value == null || value.isEmpty) return 'Ingrese una descripción';
    return null;
  }

  String? validateRequired(String? value, String field) {
    return value?.isEmpty == true ? 'El campo $field es obligatorio' : null;
  }
}
