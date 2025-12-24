// 🎨 presentations/screens/ahorro/dialogo_nueva_meta_mejorado.dart
// ============================================================================
// DIÁLOGO: Crear nueva meta con vista previa del plan (sin desbordar texto)
// ============================================================================

import 'package:finances/core/data/utils/ahorro_calculator.dart';
import 'package:finances/core/data/utils/ahorro_validator.dart';
import 'package:finances/core/data/utils/thousands_formatter.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DialogoNuevaMetaMejorado extends StatefulWidget {
  final Function(String nombre, double monto, DateTime fecha) onGuardar;
  const DialogoNuevaMetaMejorado({super.key, required this.onGuardar});

  @override
  State<DialogoNuevaMetaMejorado> createState() =>
      _DialogoNuevaMetaMejoradoState();
}

class _DialogoNuevaMetaMejoradoState extends State<DialogoNuevaMetaMejorado> {
  final _nombreController = TextEditingController();
  final _montoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _validator = AhorroValidator();

  DateTime? _fechaObjetivo;
  AhorroDesglose? _desglose;

  final _nombreFocusNode = FocusNode();
  final _montoFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _nombreFocusNode.requestFocus());
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _montoController.dispose();
    _nombreFocusNode.dispose();
    _montoFocusNode.dispose();
    super.dispose();
  }

  void _actualizarDesglose() {
    final montoLimpio = _montoController.text.replaceAll('.', '');
    final monto = double.tryParse(montoLimpio);
    if (monto != null && monto > 0 && _fechaObjetivo != null) {
      setState(() {
        _desglose = AhorroCalculator.calcularDesglose(
          montoObjetivo: monto,
          fechaObjetivo: _fechaObjetivo!,
          montoActual: 0.0, // Nueva meta → nada ahorrado aún
        );
      });
    } else {
      setState(() => _desglose = null);
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate:
          _fechaObjetivo ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (fecha != null) {
      setState(() => _fechaObjetivo = fecha);
      _actualizarDesglose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Nueva Meta de Ahorro',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Nombre
                  TextFormField(
                    controller: _nombreController,
                    focusNode: _nombreFocusNode,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Nombre de la Meta',
                        prefixIcon: Icon(Icons.flag),
                        border: OutlineInputBorder()),
                    onChanged: (_) => _actualizarDesglose(),
                    validator: _validator.validateNombre,
                  ),
                  const SizedBox(height: 12),

                  // Monto
                  TextFormField(
                    controller: _montoController,
                    focusNode: _montoFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsFormatter()],
                    decoration: const InputDecoration(
                        labelText: 'Monto Objetivo',
                        prefixText: '\$ ',
                        border: OutlineInputBorder()),
                    onChanged: (_) => _actualizarDesglose(),
                    validator: (v) => _validator.validateMonto(v, null),
                  ),
                  const SizedBox(height: 12),

                  // Fecha
                  GestureDetector(
                    onTap: _seleccionarFecha,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fecha Objetivo',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                _fechaObjetivo != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(_fechaObjetivo!)
                                    : 'Seleccionar fecha',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const Icon(Icons.calendar_today, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Vista previa del plan
                  if (_desglose != null && _desglose!.esValido)
                    _desgloseCompacto(_desglose!)
                  else if (_montoController.text.isNotEmpty &&
                      _fechaObjetivo != null)
                    const Text('Ingresa un monto válido para ver el plan',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),

                  const SizedBox(height: 20),

                  // Botones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (!_formKey.currentState!.validate() ||
                              _fechaObjetivo == null) {
                            if (_fechaObjetivo == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Selecciona una fecha')));
                            }
                            return;
                          }
                          final monto = double.tryParse(
                              _montoController.text.replaceAll('.', ''));
                          if (monto != null && monto > 0) {
                            widget.onGuardar(_nombreController.text.trim(),
                                monto, _fechaObjetivo!);
                          }
                        },
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _desgloseCompacto(AhorroDesglose d) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blue.shade700, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text('Plan de Ahorro',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
              Text(d.mensajeTiempoRestante,
                  style: const TextStyle(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          _fila('Diario', d.ahorrosDiarios, Icons.calendar_today),
          const SizedBox(height: 6),
          _fila('Semanal', d.ahorrosSemanal, Icons.date_range),
          const SizedBox(height: 6),
          _fila('Quincenal', d.ahorrosQuincenal, Icons.event_note),
          const SizedBox(height: 6),
          _fila('Mensual', d.ahorrosMensual, Icons.calendar_month),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300)),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 14),
                const SizedBox(width: 6),
                Expanded(
                    child: Text('💡 ${_periodoTexto(d.periodoRecomendado)}',
                        style: TextStyle(
                            fontSize: 10, color: Colors.green.shade700))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(String periodo, double monto, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: Colors.blue.shade600),
            const SizedBox(width: 6),
            Text(periodo, style: const TextStyle(fontSize: 11))
          ]),
          FittedBox(
            // ← Evita desbordamiento aquí también
            fit: BoxFit.scaleDown,
            child: Text(UIHelpers.formatCurrency(monto),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
          ),
        ],
      ),
    );
  }

  String _periodoTexto(String p) => switch (p) {
        'diario' => 'Ahorrar diariamente',
        'semanal' => 'Ahorrar semanalmente',
        'quincenal' => 'Ahorrar quincenalmente',
        'mensual' => 'Ahorrar mensualmente',
        _ => 'Período personalizado',
      };
}
