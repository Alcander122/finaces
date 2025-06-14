// Diálogo reusable para confirmar eliminación
import 'package:flutter/material.dart';

Future<bool?> showConfirmDeleteDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Confirmar eliminación"),
      content: const Text("¿Estás seguro de eliminar este pago?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("Cancelar"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}