// Clase que contiene los validadores para los campos del formulario de ingresos
class IngresoValidator {
  // Validar el mes
  String? validateMes(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor selecciona un mes';
    }
    return null;
  }

  // Validar el día
  String? validateDia(int? value) {
    if (value == null) {
      return 'Por favor selecciona un día';
    }
    return null;
  }

  // Validar la quincena
  String? validateQuincena(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor selecciona una quincena';
    }
    return null;
  }

  // Validar el año
  String? validateAnio(int? value) {
    if (value == null) {
      return 'Por favor selecciona un año';
    }
    return null;
  }

  // Validar la categoría
  String? validateCategoria(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor selecciona una categoría';
    }
    return null;
  }

  // Validar el concepto
  String? validateConcepto(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa un concepto';
    }
    return null;
  }

  // Validar el valor - MODIFICADO PARA MANEJAR FORMATO DE MONEDA
  String? validateValor(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa un valor';
    }

    // SOLUCIÓN 3: Limpiar el valor de formato de moneda para validación
    // Al eliminar caracteres no numéricos, podemos validar el valor correctamente [[24]]
    String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanValue.isEmpty) {
      return 'Por favor ingresa un número válido';
    }

    int? number = int.tryParse(cleanValue);
    if (number == null || number <= 0) {
      return 'El valor debe ser mayor que cero';
    }
    return null;
  }
}
