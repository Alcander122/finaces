import 'package:flutter/material.dart';
import 'package:finances/core/data/models/bank_model.dart';
import 'package:flutter/services.dart';

class DialogoNumeroCuenta extends StatefulWidget {
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
  State<DialogoNumeroCuenta> createState() => _DialogoNumeroCuentaState();
}

class _DialogoNumeroCuentaState extends State<DialogoNumeroCuenta> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.banco.nombre),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: widget.controladorCuenta,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // ✅ Solo permite números
          ],
          decoration: const InputDecoration(
            labelText: 'Número de cuenta',
            hintText: 'Ej: 1234567890',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El número de cuenta es obligatorio';
            }
            if (value.length < 10) {
              return 'Debe tener al menos 10 dígitos';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              widget.onGuardar();
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
