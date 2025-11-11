// agregar_editar_pago_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/pago_model.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/payment_provider.dart';
import 'package:finances/presentations/screens/Pagos/widgets/fecha_vencimiento_picker.dart';
import 'package:finances/presentations/screens/Pagos/widgets/dias_antes_bottom_sheet.dart';
import 'package:finances/presentations/screens/Pagos/widgets/frecuencia_bottom_sheet.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/core/data/utils/ui_helpers.dart'; // Importar UIHelpers

class AgregarEditarPagoScreen extends ConsumerStatefulWidget {
  const AgregarEditarPagoScreen({super.key});

  @override
  ConsumerState<AgregarEditarPagoScreen> createState() =>
      _AgregarEditarPagoScreenState();
}

class _AgregarEditarPagoScreenState
    extends ConsumerState<AgregarEditarPagoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _montoController = TextEditingController();
  late DateTime _fechaVencimiento;
  bool _esProgramado = false;
  int _diasAntes = 1;
  String _frecuencia = 'mensual';
  bool _datosInicializados = false;

  // Para mostrar el monto formateado en tiempo real
  String montoFormateado = '';

  @override
  void initState() {
    super.initState();
    _fechaVencimiento = DateTime.now().add(const Duration(days: 7));
    _montoController.addListener(_actualizarMontoFormateado);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_datosInicializados) {
      _inicializarDatosDesdeArgumentos();
      _datosInicializados = true;
    }
  }

  void _inicializarDatosDesdeArgumentos() {
    final args = ModalRoute.of(context)?.settings.arguments as Pago?;
    if (args != null) {
      _descripcionController.text = args.descripcion;
      _montoController.text = args.monto.toStringAsFixed(0); // Sin decimales
      _actualizarMontoFormateado(); // Forzar formato inicial
      _fechaVencimiento = args.fechaVencimiento;
      _esProgramado = args.estaProgramado;
      _diasAntes = args.notificacionAntes;
      _frecuencia = args.frecuenciaRecurrencia;
    }
  }

  void _actualizarMontoFormateado() {
    final text = _montoController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) {
      setState(() => montoFormateado = '');
      return;
    }
    final value = double.tryParse(text) ?? 0;
    setState(() => montoFormateado = UIHelpers.formatCurrency(value));
  }

  void _formatearMontoEnTiempoReal(String input) {
    // Limpiar todo lo que no sea número
    String cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.isEmpty) {
      _montoController.text = '';
      return;
    }

    // Convertir a número
    final double value = double.parse(cleaned);

    // Formatear con tu helper
    final String formatted = UIHelpers.formatCurrency(value); // → $255.555

    // Actualizar el campo SIN disparar bucle infinito
    _montoController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _mostrarDialogoDias() async {
    await showModalBottomSheet<int>(
      context: context,
      builder: (context) => DiasAntesBottomSheet(
        onDiasSeleccionados: (dias) {
          setState(() => _diasAntes = dias);
        },
      ),
    );
  }

  Future<void> _mostrarDialogoFrecuencia() async {
    await showModalBottomSheet<String>(
      context: context,
      builder: (context) => FrecuenciaBottomSheet(
        onFrecuenciaSeleccionada: (frec) {
          setState(() => _frecuencia = frec);
        },
      ),
    );
  }

  Future<void> _guardarPago() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final authState = ref.read(authProvider);
      if (authState.user == null) throw Exception("Debe estar autenticado");

      final montoTexto =
          _montoController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final monto = double.parse(montoTexto);

      final provider = ref.read(paymentProvider(authState.user!.uid).notifier);
      final nuevoPago = Pago(
        id: '',
        descripcion: _descripcionController.text.trim(),
        monto: monto,
        fechaVencimiento: _fechaVencimiento,
        estaProgramado: _esProgramado,
        notificacionAntes: _diasAntes,
        frecuenciaRecurrencia: _frecuencia,
      );

      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Pago) {
        await provider.editarPago(args.copyWith(
          descripcion: nuevoPago.descripcion,
          monto: nuevoPago.monto,
          fechaVencimiento: nuevoPago.fechaVencimiento,
          estaProgramado: nuevoPago.estaProgramado,
          notificacionAntes: nuevoPago.notificacionAntes,
          frecuenciaRecurrencia: nuevoPago.frecuenciaRecurrencia,
        ));
      } else {
        await provider.agregarPago(nuevoPago);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showErrorSnackBar(
        context: context,
        message: "Error guardando pago: $e",
      );
    }
  }

  @override
  void dispose() {
    _montoController.removeListener(_actualizarMontoFormateado);
    _descripcionController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = ModalRoute.of(context)?.settings.arguments is Pago;

    return Scaffold(
      backgroundColor: Themes.light,
      appBar: AppBar(
        backgroundColor: Themes.primary,
        title: Text(
          isEditing ? "Editar Pago" : "Nuevo Pago",
          style: const TextStyle(color: Themes.white),
        ),
        iconTheme: const IconThemeData(color: Themes.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Campo Descripción
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: "Descripción",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.trim().isEmpty ?? true
                          ? "Campo requerido"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Campo Monto con formato en tiempo real
                    TextFormField(
                      controller: _montoController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: "Monto",
                        border: const OutlineInputBorder(),
                        hintText: "0",
                      ),
                      onChanged: (value) {
                        _formatearMontoEnTiempoReal(value);
                      },
                      validator: (value) {
                        final cleaned =
                            value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                        if (cleaned.isEmpty) return "Campo requerido";
                        if (double.tryParse(cleaned) == null ||
                            double.parse(cleaned) <= 0) {
                          return "Monto inválido";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fecha
                    FechaVencimientoPicker(
                      fecha: _fechaVencimiento,
                      onChanged: (date) =>
                          setState(() => _fechaVencimiento = date),
                    ),
                    const SizedBox(height: 16),

                    // Switch de programación
                    SwitchListTile(
                      title: const Text("Pago programado/recurrente"),
                      value: _esProgramado,
                      onChanged: (value) async {
                        if (value && !_esProgramado) {
                          await _mostrarDialogoDias();
                          await _mostrarDialogoFrecuencia();
                        }
                        setState(() => _esProgramado = value);
                      },
                      activeThumbColor: Themes.degradientLight,
                    ),
                    const SizedBox(height: 8),

                    // Campos adicionales si está programado
                    if (_esProgramado) ...[
                      ListTile(
                        title: Text("Notificar $_diasAntes días antes"),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Themes.iconColor),
                          onPressed: _mostrarDialogoDias,
                        ),
                      ),
                      ListTile(
                        title: Text("Frecuencia: $_frecuencia"),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Themes.iconColor),
                          onPressed: _mostrarDialogoFrecuencia,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _guardarPago,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Themes.iconsButton,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "GUARDAR",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
