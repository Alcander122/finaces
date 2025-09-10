// presentaciones/screens/ingresos/widgets/income_form_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/core/data/utils/ingreso_validator.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';

class IngresoFrom extends StatefulWidget {
  final Ingreso? ingreso;
  final Function(Ingreso) onSave;
  final Function onCancel;

  const IngresoFrom({
    super.key,
    this.ingreso,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<IngresoFrom> createState() => _IncomeFormWidgetState();
}

class _IncomeFormWidgetState extends State<IngresoFrom> {
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double fieldMaxWidth = constraints.maxWidth * 0.9;

        return SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFieldContainer(
                  fieldMaxWidth,
                  _buildFechaIngresoField(),
                ),
                const SizedBox(height: 12),
                _buildFieldContainer(
                  fieldMaxWidth,
                  _buildQuincenaField(),
                ),
                const SizedBox(height: 12),
                _buildFieldContainer(
                  fieldMaxWidth,
                  _buildCategoriaField(),
                ),
                const SizedBox(height: 12),
                _buildFieldContainer(
                  fieldMaxWidth,
                  _buildConceptoField(),
                ),
                const SizedBox(height: 12),
                _buildFieldContainer(
                  fieldMaxWidth,
                  _buildValorField(fieldMaxWidth),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => widget.onCancel(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _saveForm,
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
        suffixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      ),
    );
  }

  Widget _buildQuincenaField() {
    return DropdownButtonFormField<String>(
      initialValue: _quincena,
      hint: const Text('Selecciona una quincena'),
      items: const ['Primera Quincena', 'Segunda Quincena', 'Diario', 'Mensual']
          .map((q) => DropdownMenuItem(value: q, child: Text(q)))
          .toList(),
      onChanged: (value) => setState(() => _quincena = value),
      decoration: InputDecoration(
        labelText: 'Periodo',
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      ),
      validator: _validator.validateQuincena,
      isExpanded: true,
    );
  }

  Widget _buildCategoriaField() {
    return DropdownButtonFormField<String>(
      value: _categoria,
      hint: const Text('Selecciona una categoría'),
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
      decoration: InputDecoration(
        labelText: 'Categoría',
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      ),
      validator: _validator.validateCategoria,
      isExpanded: true,
    );
  }

  Widget _buildConceptoField() {
    return TextFormField(
      controller: _conceptoController,
      keyboardType: TextInputType.multiline,
      minLines: 3,
      maxLines: null,
      decoration: const InputDecoration(
        labelText: 'Concepto',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      ),
      validator: _validator.validateConcepto,
    );
  }

  Widget _buildValorField(double maxWidth) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(
        width: double.infinity,
        child: TextFormField(
          controller: _valorController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Valor',
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
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
              int cursorPosition = value.length - cleanValue.length;
              _valorController.text = formatted;
              _valorController.selection = TextSelection.collapsed(
                  offset: formatted.length - cursorPosition);
            }
          },
          validator: (value) {
            String cleanValue = value?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
            return _validator
                .validateValor(cleanValue.isEmpty ? null : cleanValue);
          },
        ),
      ),
    );
  }

  Widget _buildFieldContainer(double maxWidth, Widget child) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );
  }

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

    int valorNumerico = int.parse(cleanValue);

    final ingreso = Ingreso(
      id: widget.ingreso?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      fecha: DateTime.now(),
      fechaIngreso: _fechaIngreso,
      quincena: _quincena!,
      categoria: _categoria!,
      concepto: _conceptoController.text,
      valor: valorNumerico,
    );

    widget.onSave(ingreso);
  }
}
