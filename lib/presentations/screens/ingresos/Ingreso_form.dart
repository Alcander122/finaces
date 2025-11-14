// 📌 ingreso_form.dart
// Formulario de Ingreso con diseño optimizado y responsivo
// Mantiene el nombre de clase "IngresoFrom"

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/core/data/utils/ingreso_validator.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/widgets/custom_form_container.dart';

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
  State<IngresoFrom> createState() => _IngresoFromState();
}

class _IngresoFromState extends State<IngresoFrom> {
  final _formKey = GlobalKey<FormState>();

  final _conceptoController = TextEditingController();
  final _valorController = TextEditingController();
  final _fechaController = TextEditingController();

  String? _quincena;
  String? _categoria;
  DateTime _fechaIngreso = DateTime.now();

  final IngresoValidator _validator = IngresoValidator();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Valores por defecto
    _quincena = 'Primera Quincena';
    _categoria = 'Salario';
    _fechaIngreso = DateTime.now();
    _fechaController.text = DateFormat('dd/MM/yyyy').format(_fechaIngreso);

    // Si viene un ingreso ya guardado → llenar el formulario
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

// Solo el build cambia:
  @override
  Widget build(BuildContext context) {
    return CustomFormContainer(
      formKey: _formKey,
      onCancel: widget.onCancel,
      onSave: _saveForm,
      children: [
        _buildFechaIngresoField(),
        const SizedBox(height: 12),
        _buildQuincenaField(),
        const SizedBox(height: 12),
        _buildCategoriaField(),
        const SizedBox(height: 12),
        _buildConceptoField(),
        const SizedBox(height: 12),
        _buildValorField(),
      ],
    );
  }

  /// 📌 Campo: Fecha de ingreso
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
      decoration: InputDecoration(
        labelText: 'Fecha Ingreso',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
    );
  }

  /// 📌 Campo: Quincena / Periodo
  Widget _buildQuincenaField() {
    return DropdownButtonFormField<String>(
      initialValue: _quincena,
      isExpanded: true, // ✅ evita overflow si el texto es largo
      decoration: InputDecoration(
        labelText: 'Periodo',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: const ['Primera Quincena', 'Segunda Quincena', 'Diario', 'Mensual']
          .map((q) => DropdownMenuItem(value: q, child: Text(q)))
          .toList(),
      onChanged: (value) => setState(() => _quincena = value),
      validator: _validator.validateQuincena,
    );
  }

  /// 📌 Campo: Categoría
  Widget _buildCategoriaField() {
    return DropdownButtonFormField<String>(
      initialValue: _categoria,
      isExpanded: true, // ✅ evita overflow
      decoration: InputDecoration(
        labelText: 'Categoría',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
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

  /// 📌 Campo: Concepto
  Widget _buildConceptoField() {
    return TextFormField(
      controller: _conceptoController,
      decoration: InputDecoration(
        labelText: 'Concepto',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: _validator.validateConcepto,
    );
  }

  /// 📌 Campo: Valor
  Widget _buildValorField() {
    return TextFormField(
      controller: _valorController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, // solo números
      ],
      decoration: InputDecoration(
        labelText: 'Valor',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
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

  /// 📌 Botones: Cancelar y Guardar
  Widget _buildButtonsRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => widget.onCancel(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Cancelar"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Themes.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Guardar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// 📌 Guardar formulario
  void _saveForm() {
    if (!_formKey.currentState!.validate()) return;

    String cleanValue = _valorController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanValue.isEmpty) {
      UIHelpers.showErrorSnackBar(
        context: context,
        message: 'El valor no puede estar vacío',
      );
      return;
    }

    final ingreso = Ingreso(
      id: widget.ingreso?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      fecha: DateTime.now(),
      fechaIngreso: _fechaIngreso,
      quincena: _quincena!,
      categoria: _categoria!,
      concepto: _conceptoController.text,
      valor: int.parse(cleanValue),
    );

    widget.onSave(ingreso);
  }
}
