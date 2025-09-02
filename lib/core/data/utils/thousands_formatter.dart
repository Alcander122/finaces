import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formateador de texto para campos numéricos que añade separadores de miles
/// en el formato colombiano (puntos como separadores).
///
/// IMPORTANTE: Este formateador SOLO maneja los separadores de miles,
/// NO incluye el símbolo de moneda ($) para evitar problemas al convertir
/// el texto a número. El símbolo de moneda debe manejarse en el InputDecoration.
///
/// Ejemplo de funcionamiento:
/// - Usuario escribe: "1000000"
/// - Se muestra: "1.000.000"
class ThousandsFormatter extends TextInputFormatter {
  // Configuración para formato colombiano (puntos como separadores de miles)
  final NumberFormat _formatter = NumberFormat.decimalPattern('es_CO');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Si el campo está vacío, devolvemos texto vacío
    if (newValue.text.isEmpty) {
      return TextEditingValue(text: '');
    }

    // Eliminamos cualquier carácter que no sea dígito (solo queremos números)
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Si después de limpiar no hay dígitos, devolvemos texto vacío
    if (digitsOnly.isEmpty) {
      return TextEditingValue(text: '');
    }

    // Convertimos los dígitos a entero
    int? value = int.tryParse(digitsOnly);
    if (value == null) return oldValue;

    // Formateamos el número con separadores de miles (ej: 1.000.000)
    String formattedNumber = _formatter.format(value);

    // Devolvemos el valor formateado SIN símbolo de moneda
    // El símbolo de moneda se manejará en el InputDecoration
    return TextEditingValue(
      text: formattedNumber,
      // Mantiene el cursor al final del texto
      selection: TextSelection.collapsed(offset: formattedNumber.length),
      composing: TextRange.empty,
    );
  }
}
