// utils/ui_helpers.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Clase de utilidades generales para UI.
class UIHelpers {
  // --------------------- SNACKBARS ---------------------

  /// Muestra un SnackBar de éxito (verde).
  static void showSuccessSnackBarNew({
    required BuildContext context,
    required String message,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    );
  }

  /// Muestra un SnackBar de error (rojo).
  static void showErrorSnackBar({
    required BuildContext context,
    required String message,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    );
  }

  /// Muestra un SnackBar informativo (azul).
  static void showInfoSnackBar({
    required BuildContext context,
    required String message,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Colors.blue,
      duration: const Duration(seconds: 2),
    );
  }

  /// Método privado centralizado para evitar duplicación.
  static void _showSnackBar(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.black,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --------------------- DIALOGOS ---------------------

  /// Muestra un diálogo de carga con un [CircularProgressIndicator].
  static void showLoadingDialog(
    BuildContext context, {
    String message = 'Cargando...',
  }) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Cierra el diálogo de carga mostrado con [showLoadingDialog].
  static void hideLoadingDialog(BuildContext context) {
    if (!context.mounted) return;
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  // --------------------- VALIDACIONES ---------------------

  /// Verifica si el contexto actual tiene un [Scaffold] disponible.
  static bool hasScaffold(BuildContext context) {
    try {
      Scaffold.of(context);
      return true;
    } catch (e) {
      return false;
    }
  }

  // --------------------- FORMATEO ---------------------

  /// Formatea un número a formato de moneda (COP por defecto).
  static String formatCurrency(double value) {
    final formatter = NumberFormat.decimalPattern('es_CO');
    return '\$${formatter.format(value)}';
  }

  /// Formato extendido con símbolo específico (e.g., USD).
  static String formatCurrencyWithSymbol(double value, String symbol) {
    return '$symbol${value.toStringAsFixed(2)}';
  }
}
