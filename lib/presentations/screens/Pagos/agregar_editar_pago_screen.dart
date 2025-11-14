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
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/widgets/custom_form_container.dart';
import 'package:finances/presentations/widgets/app_input_style.dart';

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

  @override
  void initState() {
    super.initState();
    _fechaVencimiento = DateTime.now().add(const Duration(days: 7));
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
      _montoController.text = args.monto.toInt().toString();
      _formatearMontoInicial();
      _fechaVencimiento = args.fechaVencimiento;
      _esProgramado = args.estaProgramado;
      _diasAntes = args.notificacionAntes;
      _frecuencia = args.frecuenciaRecurrencia;
    }
  }

  void _formatearMontoInicial() {
    final text = _montoController.text;
    if (text.isNotEmpty) {
      final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.isNotEmpty) {
        final value = double.parse(clean);
        final formatted = UIHelpers.formatCurrency(value);
        _montoController.text = formatted;
        _montoController.selection =
            TextSelection.collapsed(offset: formatted.length);
      }
    }
  }

  void _formatearMontoEnTiempoReal(String input) {
    String cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) {
      _montoController.text = '';
      return;
    }

    final double value = double.parse(cleaned);
    final String formatted = UIHelpers.formatCurrency(value);

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

      if (mounted) {
        Navigator.pop(context);
        UIHelpers.showSuccessSnackBar(
          context: context,
          message: args is Pago ? 'Pago actualizado' : 'Pago creado',
        );
      }
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showErrorSnackBar(
        context: context,
        message: "Error: $e",
      );
    }
  }

  @override
  void dispose() {
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
        foregroundColor: Colors.white,
        title: Text(isEditing ? "Editar Pago" : "Nuevo Pago"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: CustomFormContainer(
          formKey: _formKey,
          onCancel: () => Navigator.pop(context),
          onSave: _guardarPago,
          saveButtonText: 'Guardar',
          cancelButtonText: 'Cancelar',
          children: [
            // Título
            Text(
              isEditing ? "Editar Pago" : "Nuevo Pago",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Themes.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Campo: Descripción
            TextFormField(
              controller: _descripcionController,
              decoration: AppInputStyle.textField(
                label: 'Descripción',
                suffixIcon: const Icon(Icons.description),
              ),
              validator: (value) =>
                  (value?.trim().isEmpty ?? true) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),

            // Campo: Monto
            TextFormField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: AppInputStyle.textField(
                label: 'Monto',
                suffixIcon: const Icon(Icons.attach_money),
              ),
              onChanged: _formatearMontoEnTiempoReal,
              validator: (value) {
                final cleaned = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                if (cleaned.isEmpty) return 'Campo requerido';
                final monto = double.tryParse(cleaned);
                if (monto == null || monto <= 0) return 'Monto inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Fecha
            FechaVencimientoPicker(
              fecha: _fechaVencimiento,
              onChanged: (date) => setState(() => _fechaVencimiento = date),
            ),
            const SizedBox(height: 12),

            // Switch: Pago programado
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
              activeColor: Themes.primary,
            ),

            // Campos condicionales
            if (_esProgramado) ...[
              const SizedBox(height: 8),
              ListTile(
                leading:
                    const Icon(Icons.notifications, color: Themes.iconColor),
                title: Text("Notificar $_diasAntes días antes"),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Themes.iconColor),
                  onPressed: _mostrarDialogoDias,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.repeat, color: Themes.iconColor),
                title: Text("Frecuencia: $_frecuencia"),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Themes.iconColor),
                  onPressed: _mostrarDialogoFrecuencia,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
