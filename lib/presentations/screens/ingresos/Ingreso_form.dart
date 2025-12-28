// 📌 Ingreso_form.dart
// ============================================================================
// ARCHIVO: presentations/screens/ingresos/Ingreso_form.dart
// PROPÓSITO: Formulario para crear o editar un ingreso
// ESTADO: Totalmente corregido y funcional con integración al diálogo
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/core/data/utils/ingreso_validator.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/widgets/form_styles.dart';

class IngresoFrom extends StatefulWidget {
  final Ingreso? ingreso;
  final Function(Ingreso) onSave;
  final VoidCallback onCancel;

  const IngresoFrom({
    super.key,
    this.ingreso,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<IngresoFrom> createState() => IngresoFromState(); // ← Ahora pública
}

// 🔹 CLAVE: Clase pública para que ingresos_screen.dart pueda usar GlobalKey<IngresoFromState>
class IngresoFromState extends State<IngresoFrom> {
  // ============================================================================
  // PROPIEDADES DEL ESTADO
  // ============================================================================

  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _valorController = TextEditingController();
  final _fechaController = TextEditingController();

  String? _quincena;
  String? _categoria;
  DateTime _fechaIngreso = DateTime.now();

  final IngresoValidator _validator = IngresoValidator();

  // ============================================================================
  // MÉTODO PÚBLICO PARA SER LLAMADO DESDE EL DIÁLOGO
  // ============================================================================

  /// Este método es llamado por el botón "Guardar" del CustomFormDialog
  /// Permite disparar el guardado desde fuera del widget
  void submit() {
    saveForm();
  }

  // ============================================================================
  // CICLO DE VIDA
  // ============================================================================

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _quincena = 'Primera Quincena';
    _categoria = 'Salario';
    _fechaIngreso = DateTime.now();
    _fechaController.text = DateFormat('dd/MM/yyyy').format(_fechaIngreso);

    if (widget.ingreso != null) {
      final ingreso = widget.ingreso!;
      _fechaIngreso = ingreso.fechaIngreso;
      _fechaController.text =
          DateFormat('dd/MM/yyyy').format(ingreso.fechaIngreso);
      _quincena = ingreso.quincena;
      _categoria = ingreso.categoria;
      _conceptoController.text = ingreso.concepto;
      _valorController.text =
          UIHelpers.formatCurrency(ingreso.valor.toDouble());
    }
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _conceptoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFechaIngresoField(),
          const SizedBox(height: FormStyles.fieldSpacing),
          _buildQuincenaField(),
          const SizedBox(height: FormStyles.fieldSpacing),
          _buildCategoriaField(),
          const SizedBox(height: FormStyles.fieldSpacing),
          _buildConceptoField(),
          const SizedBox(height: FormStyles.fieldSpacing),
          _buildValorField(),
        ],
      ),
    );
  }

  // ============================================================================
  // CAMPOS DEL FORMULARIO
  // ============================================================================

  Widget _buildFechaIngresoField() {
    return TextFormField(
      controller: _fechaController,
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _fechaIngreso,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() {
            _fechaIngreso = picked;
            _fechaController.text = DateFormat('dd/MM/yyyy').format(picked);
          });
        }
      },
      decoration: FormStyles.buildInputDecoration(
        labelText: 'Fecha Ingreso',
        suffixIcon: Icons.calendar_today,
      ),
    );
  }

  Widget _buildQuincenaField() {
    return DropdownButtonFormField<String>(
      value: _quincena, // ← CORREGIDO: era initialValue (no existe)
      isExpanded: true,
      decoration: FormStyles.buildInputDecoration(labelText: 'Periodo'),
      items: const ['Primera Quincena', 'Segunda Quincena', 'Diario', 'Mensual']
          .map((q) => DropdownMenuItem(value: q, child: Text(q)))
          .toList(),
      onChanged: (value) => setState(() => _quincena = value),
      validator: _validator.validateQuincena,
    );
  }

  Widget _buildCategoriaField() {
    return DropdownButtonFormField<String>(
      value: _categoria, // ← CORREGIDO
      isExpanded: true,
      decoration: FormStyles.buildInputDecoration(labelText: 'Categoría'),
      items: const [
        'Salario',
        'Bonificación',
        'Reembolso',
        'Intereses',
        'Devolución',
        'Transferencia',
        'Otros'
      ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (value) => setState(() => _categoria = value),
      validator: _validator.validateCategoria,
    );
  }

  Widget _buildConceptoField() {
    return TextFormField(
      controller: _conceptoController,
      decoration: FormStyles.buildInputDecoration(labelText: 'Concepto'),
      validator: _validator.validateConcepto,
    );
  }

  Widget _buildValorField() {
    return TextFormField(
      controller: _valorController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: FormStyles.buildInputDecoration(labelText: 'Valor'),
      onChanged: (value) {
        String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
        if (cleanValue.isEmpty) {
          _valorController.text = '';
          return;
        }
        int number = int.parse(cleanValue);
        String formatted = UIHelpers.formatCurrency(number.toDouble());
        if (formatted != _valorController.text) {
          _valorController.text = formatted;
          _valorController.selection =
              TextSelection.collapsed(offset: formatted.length);
        }
      },
      validator: (value) {
        String cleanValue = value?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
        return _validator.validateValor(cleanValue.isEmpty ? null : cleanValue);
      },
    );
  }

  // ============================================================================
  // GUARDADO DEL FORMULARIO
  // ============================================================================

  void saveForm() {
    if (!_formKey.currentState!.validate()) return;

    final String cleanValue =
        _valorController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanValue.isEmpty) {
      UIHelpers.showErrorSnackBar(
        context: context,
        message: 'El valor no puede estar vacío',
      );
      return;
    }

    final nuevoIngreso = Ingreso(
      id: widget.ingreso?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      fecha: DateTime.now(),
      fechaIngreso: _fechaIngreso,
      quincena: _quincena!,
      categoria: _categoria!,
      concepto: _conceptoController.text.trim(),
      valor: int.parse(cleanValue),
    );

    widget.onSave(nuevoIngreso);
  }
}
