// agregar_editar_pago_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:finances/core/data/providers/auth_provider.dart';

import 'models/payment.dart';
import 'models/payment_enums.dart';
import 'providers/payment_form_provider.dart';
import 'providers/payment_providers.dart';
import 'widgets/fecha_vencimiento_picker.dart';
import 'widgets/payment_config_bottom_sheet.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/core/errors/handlers/db_error_handler.dart';
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
  final _titleController = TextEditingController();
  final _montoController = TextEditingController();
  bool _datosInicializados = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_datosInicializados) {
      _inicializarDatosDesdeArgumentos();
      _datosInicializados = true;
    }
  }

  void _inicializarDatosDesdeArgumentos() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Payment) {
      Future.microtask(() {
        ref.read(paymentFormProvider.notifier).loadPayment(args);
      });
      _titleController.text = args.title;
      _montoController.text = args.totalAmount.toInt().toString();
      _formatearMontoInicial();
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

  Future<void> _guardarPago() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final authState = ref.read(authProvider);
      if (authState.user == null) throw Exception("Debe estar autenticado");

      final montoTexto =
          _montoController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final monto = double.parse(montoTexto);

      final provider = ref.read(paymentControllerProvider.notifier);
      final draft = ref.read(paymentFormProvider);

      final isEditing = ModalRoute.of(context)?.settings.arguments is Payment;

      final paymentToSave = draft.copyWith(
        title: _titleController.text.trim(),
        totalAmount: monto,
        userId: authState.user!.uid,
      );

      if (isEditing) {
        await provider.updatePayment(paymentToSave);
      } else {
        await provider.createPayment(paymentToSave);
      }

      if (mounted) {
        Navigator.pop(context);
        UIHelpers.showSuccessSnackBar(
          context: context,
          message: isEditing ? 'Pago actualizado' : 'Pago creado',
        );
      }
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showErrorSnackBar(
        context: context,
        message: DbErrorHandler.handle(e),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = ModalRoute.of(context)?.settings.arguments is Payment;
    final draft = ref.watch(paymentFormProvider);
    final isProgramado = draft.recurrence.unit != FrequencyUnit.none;

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

            TextFormField(
              controller: _titleController,
              decoration: AppInputStyle.textField(
                label: 'Título del Pago',
                suffixIcon: const Icon(Icons.description),
              ),
              validator: (value) =>
                  (value?.trim().isEmpty ?? true) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: AppInputStyle.textField(
                label: 'Monto a Pagar',
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
              fecha: draft.nextDueDate,
              onChanged: (date) {
                final tzDate = tz.TZDateTime.from(date, tz.local);
                ref.read(paymentFormProvider.notifier).setNextDueDate(tzDate);
              },
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text("Pago programado/recurrente"),
              value: isProgramado,
              onChanged: (value) {
                if (value) {
                  ref
                      .read(paymentFormProvider.notifier)
                      .updateFrequency(FrequencyUnit.months);
                  PaymentConfigBottomSheet.show(context);
                } else {
                  ref
                      .read(paymentFormProvider.notifier)
                      .updateFrequency(FrequencyUnit.none);
                }
              },
              activeThumbColor: Themes.primary,
            ),

            if (isProgramado) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Themes.greyDisabled.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.repeat, color: Themes.primary),
                  title: Text(
                    "Frecuencia: ${draft.recurrence.unit.name.toUpperCase()}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      "Avisar: ${draft.notifyDaysBefore.join(', ')} días antes a las ${draft.notificationTimeOfDay?.hour.toString().padLeft(2, '0')}:${draft.notificationTimeOfDay?.minute.toString().padLeft(2, '0')}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Themes.primary),
                    onPressed: () => PaymentConfigBottomSheet.show(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Notificaciones activas'),
                subtitle: Text(
                  draft.status == PaymentStatus.pending
                      ? 'Recibirás recordatorios según esta configuración.'
                      : 'Las notificaciones de este pago están pausadas.',
                ),
                value: draft.status == PaymentStatus.pending,
                onChanged: (value) {
                  ref.read(paymentFormProvider.notifier).setStatus(
                      value ? PaymentStatus.pending : PaymentStatus.paused);
                },
                activeColor: Themes.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
