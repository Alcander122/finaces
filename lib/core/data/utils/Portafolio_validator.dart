class FormValidator {
  String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un monto';
    }
    if (double.tryParse(value) == null) {
      return 'Por favor ingrese un número válido';
    }
    if (double.parse(value) <= 0) {
      return 'El monto debe ser positivo';
    }
    return null;
  }

  String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese una descripción';
    }
    return null;
  }
}
