class AhorroValidator {
  String? validateNombre(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un nombre';
    }
    return null;
  }

  String? validateMonto(String? value, double? maxMonto) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un monto';
    }
    final monto = double.tryParse(value);
    if (monto == null || monto <= 0) {
      return 'Monto inválido';
    }
    if (maxMonto != null && monto > maxMonto) {
      return 'Monto excede el disponible';
    }
    return null;
  }
}
