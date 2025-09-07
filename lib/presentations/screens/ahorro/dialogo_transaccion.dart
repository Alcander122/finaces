import 'package:finances/core/data/utils/ahorro_validator.dart';
import 'package:finances/core/data/utils/thousands_formatter.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
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
    _montoController.dispose();
    _descripcionController.dispose();
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
            // CAMPO DE MONTO - CORREGIDO
            TextFormField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              // Añadimos el formateador de miles SIN símbolo de moneda
              inputFormatters: [ThousandsFormatter()],
              focusNode: _montoFocusNode,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Monto',
                // El símbolo $ se muestra aquí como prefijo, NO en el formateador
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: Colors.black),
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
              // PASO CRÍTICO: Limpiar los puntos del formato antes de convertir a número
              // Ejemplo: "1.000.000" → "1000000"
              final montoLimpio = _montoController.text.replaceAll('.', '');

              // Usar tryParse para evitar excepciones si el valor no es numérico
              final monto = double.tryParse(montoLimpio);

              // Validar que el monto sea válido
              if (monto == null || monto <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'El monto debe ser un número válido y mayor que cero'),
                  ),
                );
                return;
              }

              // Verificar si es un retiro y si excede el monto disponible
              if (widget.maxMonto != null && monto > widget.maxMonto!) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'No puedes retirar más de ${UIHelpers.formatCurrency(widget.maxMonto!)}'),
                  ),
                );
                return;
              }

              final descripcion = _descripcionController.text.trim();
              widget.onGuardar(monto, descripcion);
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
