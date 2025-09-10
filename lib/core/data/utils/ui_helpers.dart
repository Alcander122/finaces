// utils/ui_helpers.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Clase de utilidades generales para UI.
/// Contiene métodos para mostrar SnackBars, diálogos,
/// validaciones de contexto y formateo de números.
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

  /// 🔒 Método privado centralizado para evitar duplicación
  static void _showSnackBar(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.black,
    Duration duration = const Duration(seconds: 2),
  }) {
    // ⚠️ Primero: verificar que el widget no esté desmontado
    if (!context.mounted) {
      debugPrint("⚠️ Context desmontado, no se puede mostrar SnackBar.");
      return;
    }

    // ✅ Intentamos obtener el ScaffoldMessenger asociado al contexto
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (messenger == null) {
      // ⚠️ Contexto inválido, no hay Scaffold activo
      debugPrint(
          "⚠️ No se encontró ScaffoldMessenger. No se puede mostrar SnackBar.");
      return;
    }

    // ✅ Limpia los SnackBars previos antes de mostrar uno nuevo
    messenger.clearSnackBars();

    // ✅ Mostrar SnackBar de forma segura
    messenger.showSnackBar(
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
    if (!context.mounted) return; // ⚠️ Evita mostrar si el widget ya no existe
    showDialog(
      context: context,
      barrierDismissible: false, // ❌ No se puede cerrar tocando fuera
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
    if (!context.mounted) return; // ⚠️ Evita cerrar si ya no existe
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

  /// Formatea un número a formato de moneda local (COP).
  static String formatCurrency(double value) {
    final formatter = NumberFormat.decimalPattern('es_CO');
    return '\$${formatter.format(value)}';
  }
}
