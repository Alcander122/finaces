// ahorro_validator.dart
// 📌 Centralizamos las validaciones relacionadas con el ahorro.
import '../../../core/data/utils/ui_helpers.dart';

class AhorroValidator {
  /// ✅ Valida que el nombre no esté vacío
  String? validateNombre(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un nombre';
    }
    return null;
  }

  /// ✅ Valida que el monto sea un número válido, positivo
  ///    y que no supere un monto máximo (ej: meta restante o saldo disponible).
  ///    Acepta valores con formato (puntos, comas, símbolos) y los limpia.
  String? validateMonto(String? value, double? maxMonto) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un monto';
    }

    // 🔹 Limpiar el valor: eliminamos símbolos como $, puntos, comas y espacios
    final cleaned = value.replaceAll(RegExp(r'[\$,.\s]'), '');

    // 🔹 Intentamos convertir a número
    final monto = double.tryParse(cleaned);

    // ❌ No es válido si no es número o es <= 0
    if (monto == null || monto <= 0) {
      return 'Monto inválido';
    }

    // ❌ Validamos que no supere el máximo permitido (meta o saldo)
    if (maxMonto != null && monto > maxMonto) {
      return 'El monto no puede superar ${UIHelpers.formatCurrency(maxMonto)}';
    }

    return null; // ✅ Si todo está bien
  }
}
