// 📌 Ingreso_form.dart
// ============================================================================
// ARCHIVO: presentations/screens/ingresos/Ingreso_form.dart
// PROPÓSITO: Formulario para crear/editar ingresos
// DESCRIPCIÓN: Formulario con campos validados y estilos centralizados
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/core/data/utils/ingreso_validator.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/widgets/form_styles.dart';

class IngresoFrom extends StatefulWidget {
  // ============================================================================
  //  PROPIEDADES
  // ============================================================================

  /// Ingreso a editar (null si es nuevo)
  final Ingreso? ingreso;

  /// Callback cuando se guarda el formulario
  final Function(Ingreso) onSave;

  /// Callback cuando se cancela el formulario
  final VoidCallback onCancel;

  // ============================================================================
  //  CONSTRUCTOR
  // ============================================================================

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
  // ============================================================================
  // PROPIEDADES DEL ESTADO
  // ============================================================================

  /// GlobalKey para validar el formulario
  final _formKey = GlobalKey<FormState>();

  /// Controladores de texto para los campos
  final _conceptoController = TextEditingController();
  final _valorController = TextEditingController();
  final _fechaController = TextEditingController();

  /// Valores seleccionados en dropdowns
  String? _quincena;
  String? _categoria;
  DateTime _fechaIngreso = DateTime.now();

  /// Validador de ingresos
  final IngresoValidator _validator = IngresoValidator();

  // ============================================================================
  //  CICLO DE VIDA
  // ============================================================================

  @override
  void initState() {
    super.initState();
    // Inicializar el formulario con valores por defecto o datos existentes
    _initializeForm();
  }

  /// Inicializa el formulario con valores por defecto o datos existentes
  void _initializeForm() {
    // ========== VALORES POR DEFECTO ==========
    _quincena = 'Primera Quincena';
    _categoria = 'Salario';
    _fechaIngreso = DateTime.now();
    _fechaController.text = DateFormat('dd/MM/yyyy').format(_fechaIngreso);

    // ========== SI VIENE UN INGRESO GUARDADO, LLENAR EL FORMULARIO ==========
    if (widget.ingreso != null) {
      final ingreso = widget.ingreso!;

      // Fecha del ingreso
      _fechaIngreso = ingreso.fechaIngreso;
      _fechaController.text =
          DateFormat('dd/MM/yyyy').format(ingreso.fechaIngreso);

      // Quincena/Período
      _quincena = ingreso.quincena;

      // Categoría
      _categoria = ingreso.categoria;

      // Concepto
      _conceptoController.text = ingreso.concepto;

      // Valor (formateado como moneda)
      _valorController.text =
          UIHelpers.formatCurrency(ingreso.valor.toDouble());
    }
  }

  @override
  void dispose() {
    // Liberar recursos de los controladores
    _fechaController.dispose();
    _conceptoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  // ============================================================================
  //  BUILD - ESTRUCTURA PRINCIPAL
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ========== CAMPO 1: FECHA DE INGRESO ==========
          _buildFechaIngresoField(),
          const SizedBox(height: FormStyles.fieldSpacing),

          // ========== CAMPO 2: PERÍODO (QUINCENA) ==========
          _buildQuincenaField(),
          const SizedBox(height: FormStyles.fieldSpacing),

          // ========== CAMPO 3: CATEGORÍA ==========
          _buildCategoriaField(),
          const SizedBox(height: FormStyles.fieldSpacing),

          // ========== CAMPO 4: CONCEPTO ==========
          _buildConceptoField(),
          const SizedBox(height: FormStyles.fieldSpacing),

          // ========== CAMPO 5: VALOR ==========
          _buildValorField(),
        ],
      ),
    );
  }

  // ============================================================================
  // CAMPOS DEL FORMULARIO
  // ============================================================================

  /// Campo: Fecha de Ingreso
  ///
  /// Características:
  /// - Campo de solo lectura (se abre un date picker al tocar)
  /// - Formato: dd/MM/yyyy
  /// - Icono de calendario
  Widget _buildFechaIngresoField() {
    return TextFormField(
      controller: _fechaController,
      readOnly: true, // Solo lectura, se abre date picker al tocar

      // Al tocar el campo, abre el date picker
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _fechaIngreso,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );

        // Si el usuario selecciona una fecha
        if (picked != null) {
          setState(() {
            _fechaIngreso = picked;
            _fechaController.text = DateFormat('dd/MM/yyyy').format(picked);
          });
        }
      },

      // Decoración del campo
      decoration: FormStyles.buildInputDecoration(
        labelText: 'Fecha Ingreso',
        suffixIcon: Icons.calendar_today,
      ),
    );
  }

  /// Campo: Quincena / Período
  ///
  /// Características:
  /// - Dropdown con opciones predefinidas
  /// - Opciones: Primera Quincena, Segunda Quincena, Diario, Mensual
  /// - Validación requerida
  Widget _buildQuincenaField() {
    return DropdownButtonFormField<String>(
      initialValue: _quincena,
      isExpanded: true, // Evita overflow si el texto es largo

      // Decoración del campo
      decoration: FormStyles.buildInputDecoration(
        labelText: 'Periodo',
      ),

      // Opciones del dropdown
      items: const ['Primera Quincena', 'Segunda Quincena', 'Diario', 'Mensual']
          .map((q) => DropdownMenuItem(value: q, child: Text(q)))
          .toList(),

      // Callback cuando cambia el valor
      onChanged: (value) => setState(() => _quincena = value),

      // Validación
      validator: _validator.validateQuincena,
    );
  }

  /// Campo: Categoría
  ///
  /// Características:
  /// - Dropdown con categorías predefinidas
  /// - Opciones: Salario, Bonificación, Reembolso, Intereses, Devolución, Transferencia, Otros
  /// - Validación requerida
  Widget _buildCategoriaField() {
    return DropdownButtonFormField<String>(
      initialValue: _categoria,
      isExpanded: true, // Evita overflow

      // Decoración del campo
      decoration: FormStyles.buildInputDecoration(
        labelText: 'Categoría',
      ),

      // Opciones del dropdown
      items: const [
        'Salario',
        'Bonificación',
        'Reembolso',
        'Intereses',
        'Devolución',
        'Transferencia',
        'Otros'
      ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),

      // Callback cuando cambia el valor
      onChanged: (value) => setState(() => _categoria = value),

      // Validación
      validator: _validator.validateCategoria,
    );
  }

  /// Campo: Concepto
  ///
  /// Características:
  /// - Campo de texto libre
  /// - Validación requerida
  Widget _buildConceptoField() {
    return TextFormField(
      controller: _conceptoController,

      // Decoración del campo
      decoration: FormStyles.buildInputDecoration(
        labelText: 'Concepto',
      ),

      // Validación
      validator: _validator.validateConcepto,
    );
  }

  /// Campo: Valor
  ///
  /// Características:
  /// - Solo acepta números
  /// - Se formatea automáticamente como moneda (ej: $ 1.000.000)
  /// - Validación requerida
  Widget _buildValorField() {
    return TextFormField(
      controller: _valorController,
      keyboardType: TextInputType.number,

      // Solo permite dígitos
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],

      // Decoración del campo
      decoration: FormStyles.buildInputDecoration(
        labelText: 'Valor',
      ),

      // Formatea el valor como moneda mientras se escribe
      onChanged: (value) {
        // Elimina caracteres no numéricos
        String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');

        // Si está vacío, no hacer nada
        if (cleanValue.isEmpty) {
          _valorController.text = '';
          return;
        }

        // Convertir a número y formatear como moneda
        int number = int.parse(cleanValue);
        String formatted = UIHelpers.formatCurrency(number.toDouble());

        // Solo actualizar si el valor cambió
        if (formatted != _valorController.text) {
          _valorController.text = formatted;
          // Posicionar el cursor al final
          _valorController.selection =
              TextSelection.collapsed(offset: formatted.length);
        }
      },

      // Validación
      validator: (value) {
        // Eliminar caracteres no numéricos
        String cleanValue = value?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
        // Validar usando el validador
        return _validator.validateValor(cleanValue.isEmpty ? null : cleanValue);
      },
    );
  }

  // ============================================================================
  // GUARDAR FORMULARIO
  // ============================================================================

  /// Valida y guarda el formulario
  ///
  /// Proceso:
  /// 1. Valida todos los campos
  /// 2. Extrae el valor numérico del campo de valor
  /// 3. Crea un objeto Ingreso
  /// 4. Llama al callback onSave
  void saveForm() {
    // Validar el formulario
    if (!_formKey.currentState!.validate()) return;

    // Extraer el valor numérico (eliminar caracteres de formato)
    String cleanValue = _valorController.text.replaceAll(RegExp(r'[^\d]'), '');

    // Verificar que el valor no esté vacío
    if (cleanValue.isEmpty) {
      UIHelpers.showErrorSnackBar(
        context: context,
        message: 'El valor no puede estar vacío',
      );
      return;
    }

    // Crear objeto Ingreso con los datos del formulario
    final ingreso = Ingreso(
      // ID: usar el existente o generar uno nuevo basado en timestamp
      id: widget.ingreso?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),

      // Fecha de creación
      fecha: DateTime.now(),

      // Fecha del ingreso (seleccionada por el usuario)
      fechaIngreso: _fechaIngreso,

      // Período (quincena)
      quincena: _quincena!,

      // Categoría
      categoria: _categoria!,

      // Concepto
      concepto: _conceptoController.text,

      // Valor (convertido a entero)
      valor: int.parse(cleanValue),
    );

    // Llamar al callback onSave con el ingreso creado
    widget.onSave(ingreso);
  }
}
