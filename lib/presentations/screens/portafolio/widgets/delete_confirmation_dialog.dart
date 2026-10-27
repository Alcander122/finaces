import 'package:flutter/material.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/theme/theme.dart';

/// Diálogo modal accesible para confirmar la eliminación de un portafolio o inversión.
class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = PortafolioStrings.eliminarBtn,
    this.cancelText = PortafolioStrings.cancelarBtn,
  });

  /// Muestra el diálogo y retorna `true` si el usuario confirma la acción.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = PortafolioStrings.eliminarBtn,
    String cancelText = PortafolioStrings.cancelarBtn,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => DeleteConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.dialogBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: context.isDarkMode ? context.colors.onSurface : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(
          color: context.isDarkMode ? context.colors.onSurfaceVariant : const Color(0xFF4B5563),
          fontSize: 14,
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(80, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(90, 48),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
