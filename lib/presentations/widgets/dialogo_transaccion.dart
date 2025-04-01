import 'package:finances/core/data/utils/ahorro_validator.dart';
import 'package:flutter/material.dart';

class DialogoTransaccion extends StatefulWidget {
  final Function(double) onGuardar;
  final double? maxMonto;

  const DialogoTransaccion({
    super.key,
    required this.onGuardar,
    this.maxMonto,
  });

  @override
  State<DialogoTransaccion> createState() => _DialogoTransaccionState();
}

class _DialogoTransaccionState extends State<DialogoTransaccion> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AhorroValidator _validator = AhorroValidator();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Transacción'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monto'),
          validator: (value) =>
              _validator.validateMonto(value, widget.maxMonto),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onGuardar(double.parse(_controller.text));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Transacción guardada correctamente')),
              );
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
