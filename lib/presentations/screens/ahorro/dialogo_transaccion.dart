import 'package:finances/core/data/utils/ahorro_validator.dart';
import 'package:flutter/material.dart';

class DialogoTransaccion extends StatefulWidget {
  final Function(double, String) onGuardar;
  final double? maxMonto;
  final String titulo; // Título personalizado

  const DialogoTransaccion({
    super.key,
    required this.onGuardar,
    this.maxMonto,
    this.titulo = 'Nueva Transacción',
  });

  @override
  State<DialogoTransaccion> createState() => _DialogoTransaccionState();
}

class _DialogoTransaccionState extends State<DialogoTransaccion> {
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AhorroValidator _validator = AhorroValidator();

  // FocusNodes para controlar el foco en los campos
  final FocusNode _montoFocusNode = FocusNode();
  final FocusNode _descripcionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Solicitar foco en el campo de monto al abrir el diálogo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _montoFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _montoFocusNode.dispose();
    _descripcionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(widget.titulo),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              focusNode: _montoFocusNode,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              onEditingComplete: () =>
                  FocusScope.of(context).requestFocus(_descripcionFocusNode),
              validator: (value) =>
                  _validator.validateMonto(value, widget.maxMonto),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              focusNode: _descripcionFocusNode,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _descripcionFocusNode.unfocus(),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final monto = double.parse(_montoController.text);
              final descripcion = _descripcionController.text.trim();
              widget.onGuardar(monto, descripcion);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transacción guardada correctamente'),
                ),
              );
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
