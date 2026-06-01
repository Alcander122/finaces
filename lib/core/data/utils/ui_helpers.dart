// utils/ui_helpers.dart
import 'package:finances/core/errors/handlers/auth_error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Clase de utilidades generales para UI: SnackBars, diálogos, validaciones.
class UIHelpers {
  // ===================== SNACKBARS =====================

  /// Muestra un SnackBar de éxito (verde)
  static void showSuccessSnackBar({
    required BuildContext context,
    required String message,
  }) {
    _showSnackBar(context, message, backgroundColor: Colors.green);
  }

  /// Muestra un SnackBar de error (rojo)
  static void showErrorSnackBar({
    required BuildContext context,
    required String message,
  }) {
    _showSnackBar(context, message, backgroundColor: Colors.red);
  }

  /// Muestra un SnackBar de error de Firebase usando AuthErrorHandler
  static void showErrorSnackBarFromAuth({
    required BuildContext context,
    required FirebaseAuthException error,
  }) {
    final message = AuthErrorHandler.handle(error);
    _showSnackBar(context, message, backgroundColor: Colors.red);
  }

  /// Muestra un SnackBar informativo (azul)
  static void showInfoSnackBar({
    required BuildContext context,
    required String message,
  }) {
    _showSnackBar(context, message, backgroundColor: Colors.blue);
  }

  /// Método privado: evita duplicación y asegura seguridad
  static void _showSnackBar(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.black,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ===================== DIÁLOGOS =====================

  /// Muestra diálogo de carga
  static void showLoadingDialog(BuildContext context,
      {String message = 'Cargando...'}) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
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

  /// Cierra diálogo de carga
  static void hideLoadingDialog(BuildContext context) {
    if (!context.mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  // ===================== FORMATEO =====================

  static String formatCurrency(double value, {bool showDecimals = false}) {
    final formatter = NumberFormat.decimalPattern('es_CO');
    return '\$${formatter.format(showDecimals ? value : value.round())}';
  }

  static String formatCurrencyAmount(double value, {String currency = 'COP'}) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: currency == 'COP' ? '\$' : (currency == 'USD' ? 'US\$' : '€'),
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  static String formatRate(double rate, {String toCurrency = 'COP'}) {
    final formatter = NumberFormat('#,##0.####', 'es_CO');
    final symbol =
        toCurrency == 'COP' ? '\$' : (toCurrency == 'USD' ? 'US\$' : '€');
    return '$symbol${formatter.format(rate)}';
  }
}
