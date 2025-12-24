// 🎨 presentations/screens/ahorro/dialogo_nueva_meta_mejorado.dart
// ============================================================================
// WIDGET: DialogoNuevaMetaMejorado
// PROPÓSITO: Diálogo compacto para crear una nueva meta de ahorro
// ============================================================================
import 'package:finances/core/data/utils/ahorro_calculator.dart';
import 'package:finances/core/data/utils/ahorro_validator.dart';
import 'package:finances/core/data/utils/thousands_formatter.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DialogoNuevaMetaMejorado extends StatefulWidget {
  final Function(String nombre, double monto, DateTime fecha) onGuardar;

  const DialogoNuevaMetaMejorado({
    super.key,
    required this.onGuardar,
  });

  @override
  State<DialogoNuevaMetaMejorado> createState() =>
      _DialogoNuevaMetaMejoradoState();
}

class _DialogoNuevaMetaMejoradoState extends State<DialogoNuevaMetaMejorado> {
  // ==========================================================================
  // CONTROLADORES
  // ==========================================================================
  final _nombreController = TextEditingController();
  final _montoController = TextEditingController();

  // ==========================================================================
  // VALIDACIÓN Y ESTADO
  // ==========================================================================
  final _formKey = GlobalKey<FormState>();
  final AhorroValidator _validator = AhorroValidator();
  DateTime? _fechaObjetivo;
  AhorroDesglose? _desglose;

  // ==========================================================================
  // FOCUS NODES
  // ==========================================================================
  final FocusNode _nombreFocusNode = FocusNode();
  final FocusNode _montoFocusNode = FocusNode();

  // ==========================================================================
  // CICLO DE VIDA
  // ==========================================================================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nombreFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _montoController.dispose();
    _nombreFocusNode.dispose();
    _montoFocusNode.dispose();
    super.dispose();
  }

  // ==========================================================================
  // MÉTODOS PRIVADOS
  // ==========================================================================
  void _actualizarDesglose() {
    final montoLimpio = _montoController.text.replaceAll('.', '');
    final monto = double.tryParse(montoLimpio);

    if (monto != null && monto > 0 && _fechaObjetivo != null) {
      setState(() {
        _desglose = AhorroCalculator.calcularDesglose(
          montoObjetivo: monto,
          fechaObjetivo: _fechaObjetivo!,
        );
      });
    } else {
      setState(() {
        _desglose = null;
      });
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
      setState(() {
        _fechaObjetivo = fecha;
      });
      _actualizarDesglose();
    }
  }

  // ==========================================================================
  // CONSTRUCCIÓN DE LA UI
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 400,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nueva Meta de Ahorro',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Campo: Nombre
                  TextFormField(
                    controller: _nombreController,
                    focusNode: _nombreFocusNode,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la Meta',
                      prefixIcon: const Icon(Icons.flag),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (_) => _actualizarDesglose(),
                    validator: _validator.validateNombre,
                  ),
                  const SizedBox(height: 12),

                  // Campo: Monto
                  TextFormField(
                    controller: _montoController,
                    focusNode: _montoFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsFormatter()],
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Monto Objetivo',
                      prefixText: '\$ ',
                      prefixStyle: const TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (_) => _actualizarDesglose(),
                    validator: (value) => _validator.validateMonto(value, null),
                  ),
                  const SizedBox(height: 12),

                  // Selector de fecha
                  GestureDetector(
                    onTap: _seleccionarFecha,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
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

                  // Desglose compacto
                  if (_desglose != null && _desglose!.esValido)
                    _construirDesgloseCompacto(_desglose!)
                  else if (_montoController.text.isNotEmpty &&
                      _fechaObjetivo != null)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Ingresa un monto válido para ver el desglose',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Botones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          // Validamos formulario y fecha
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }

                          if (_fechaObjetivo == null) {
                            // 🔥 PROTECCIÓN CLAVE: evitamos usar context si el widget ya no está montado
                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Por favor selecciona una fecha objetivo'),
                              ),
                            );
                            return;
                          }

                          // Procesamos el monto
                          final montoLimpio =
                              _montoController.text.replaceAll('.', '');
                          final monto = double.tryParse(montoLimpio);

                          if (monto != null && monto > 0) {
                            widget.onGuardar(
                              _nombreController.text.trim(),
                              monto,
                              _fechaObjetivo!,
                            );
                            Navigator.pop(context);
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

  // ==========================================================================
  // WIDGETS AUXILIARES (sin cambios, solo para completar el archivo)
  // ==========================================================================
  Widget _construirDesgloseCompacto(AhorroDesglose desglose) {
    // ... (tu código original, sin cambios)
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blue.shade700, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Plan de Ahorro',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700)),
              ),
              Text(desglose.mensajeTiempoRestante,
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 10),
          _construirFilaDesgloseCompacta(
              'Diario', desglose.ahorrosDiarios, Icons.calendar_today),
          const SizedBox(height: 6),
          _construirFilaDesgloseCompacta(
              'Semanal', desglose.ahorrosSemanal, Icons.date_range),
          const SizedBox(height: 6),
          _construirFilaDesgloseCompacta(
              'Quincenal', desglose.ahorrosQuincenal, Icons.event_note),
          const SizedBox(height: 6),
          _construirFilaDesgloseCompacta(
              'Mensual', desglose.ahorrosMensual, Icons.calendar_month),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '💡 ${_obtenerNombrePeriodo(desglose.periodoRecomendado)}',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFilaDesgloseCompacta(
      String periodo, double monto, IconData icono) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icono, size: 14, color: Colors.blue.shade600),
              const SizedBox(width: 6),
              Text(periodo, style: const TextStyle(fontSize: 11)),
            ],
          ),
          Text(UIHelpers.formatCurrency(monto),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
        ],
      ),
    );
  }

  String _obtenerNombrePeriodo(String periodo) {
    switch (periodo) {
      case 'diario':
        return 'Ahorrar diariamente';
      case 'semanal':
        return 'Ahorrar semanalmente';
      case 'quincenal':
        return 'Ahorrar quincenalmente';
      case 'mensual':
        return 'Ahorrar mensualmente';
      default:
        return 'Período personalizado';
    }
  }
}
