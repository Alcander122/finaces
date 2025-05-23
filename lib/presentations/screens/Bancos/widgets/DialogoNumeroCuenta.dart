// Diálogo para ingresar el número de cuenta
import 'package:flutter/material.dart';
import 'package:finances/core/data/models/bank_model.dart';

class DialogoNumeroCuenta extends StatelessWidget {
  final BancoModelo banco;
  final TextEditingController controladorCuenta;
  final VoidCallback onGuardar;

  const DialogoNumeroCuenta({
    super.key,
    required this.banco,
    required this.controladorCuenta,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(banco.nombre),
      content: TextField(
        controller: controladorCuenta,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Número de cuenta'),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: onGuardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}