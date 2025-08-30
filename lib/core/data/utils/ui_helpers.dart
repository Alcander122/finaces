// utils/ui_helpers.dart
import 'package:flutter/material.dart';

class UIHelpers {
  // Muestra un SnackBar de éxito usando ScaffoldMessenger (enfoque moderno)
  static void showSuccessSnackBarNew(
      {required BuildContext context, required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Muestra un SnackBar de error
  static void showErrorSnackBar(
      {required BuildContext context, required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Muestra un SnackBar de información
  static void showInfoSnackBar(
      {required BuildContext context, required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Muestra un diálogo de carga
  static void showLoadingDialog(BuildContext context,
      {String message = 'Cargando...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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

  // Cierra el diálogo de carga
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // Método adicional para verificar si el contexto tiene un Scaffold ancestor
  static bool hasScaffold(BuildContext context) {
    try {
      Scaffold.of(context);
      return true;
    } catch (e) {
      return false;
    }
  }
}
