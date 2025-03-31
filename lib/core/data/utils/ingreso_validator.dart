class IngresoValidator {
  String? validateMes(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor selecciona un mes';
    }
    return null;
  }

  String? validateDia(int? value) {
    if (value == null) {
      return 'Por favor selecciona un día';
    }
    return null;
  }

  String? validateQuincena(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor selecciona una quincena';
    }
    return null;
  }

  String? validateCategoria(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor selecciona una categoría';
    }
    return null;
  }

  String? validateConcepto(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa un concepto';
    }
    return null;
  }

  String? validateValor(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa un valor';
    }
    if (int.tryParse(value) == null) {
      return 'Por favor ingresa un número válido';
    }
    if (int.parse(value) <= 0) {
      return 'El valor debe ser mayor que cero';
    }
    return null;
  }
}
