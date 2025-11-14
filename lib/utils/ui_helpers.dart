// core/data/utils/ui_helpers.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UIHelpers {
  // Formatear moneda con separador de miles y símbolo $
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO', // Cambia según tu región
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Mostrar SnackBar de éxito
  static void showSuccessSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: Colors.green[700],
      duration: duration,
    );
  }

  // Mostrar SnackBar de error
  static void showErrorSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 5),
  }) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: Colors.red[800],
      duration: duration,
    );
  }

  // Método privado reutilizable
  static void _showSnackBar({
    required BuildContext context,
    required String message,
    required Color? backgroundColor,
    required Duration duration,
  }) {
    // Compatible con Flutter < 3.7
    if (context.mounted == false) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: duration,
        ),
      );
  }

  // Cálculo: monto semanal recomendado
  static String calcularMontoSemanal(
    double montoRestante,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) {
    final dias = fechaFin.difference(fechaInicio).inDays;
    if (dias <= 0) return formatCurrency(0);
    final semanas = dias / 7;
    final monto = montoRestante / semanas;
    return formatCurrency(monto.toInt() as double);
  }

  // Cálculo: monto mensual recomendado
  static String calcularMontoMensual(
    double montoRestante,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) {
    int meses = (fechaFin.year - fechaInicio.year) * 12 +
        fechaFin.month -
        fechaInicio.month;
    if (fechaFin.day < fechaInicio.day) meses--;
    meses = meses > 0 ? meses : 1;
    final monto = montoRestante / meses;
    return formatCurrency(monto.toInt() as double);
  }
}
