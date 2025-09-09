import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../../core/data/utils/ui_helpers.dart';

class CurrencyFormatterFromHelper extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final number = double.tryParse(digits) ?? 0;
    final formatted = UIHelpers.formatCurrency(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class EgresoForm extends ConsumerStatefulWidget {
  final Egreso? egreso;

  const EgresoForm({super.key, this.egreso});

  @override
  ConsumerState<EgresoForm> createState() => _EgresoFormState();
}

class _EgresoFormState extends ConsumerState<EgresoForm> {
  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _valorController = TextEditingController();
  final _descripcionController = TextEditingController();

  String? _quincena;
  // ✅ Inicialización segura con valores por defecto
  DateTime fechaPago = DateTime.now();
  String? _categoria;
  String? _estado;
  DateTime _fechaActual = DateTime.now();

  final List<String> _quincenas = [
    'Primera Quincena',
    'Segunda Quincena',
    'Diario',
    'Mensual'
  ];
  final List<String> _categorias = [
    'Alimentación',
    'Transporte',
    'Vivienda',
    'Entretenimiento',
    'Ahorro',
    'Vacaciones',
    'Transferencia',
    'Otros'
  ];
  final List<String> _estados = ['Pendiente', 'Cancelado'];

  final Map<String, String> _quincenaToDisplay = {
    'Primera': 'Primera Quincena',
    'Segunda': 'Segunda Quincena',
    'Diario': 'Diario',
    'Mensual': 'Mensual',
  };

  final Map<String, String> _displayToQuincena = {
    'Primera Quincena': 'Primera',
    'Segunda Quincena': 'Segunda',
    'Diario': 'Diario',
    'Mensual': 'Mensual',
  };

  @override
  void initState() {
    super.initState();

    // ✅ Inicialización segura con valores por defecto
    fechaPago = DateTime.now();
    _fechaActual = DateTime.now();

    // Si estamos editando un egreso existente, cargamos sus datos
    if (widget.egreso != null) {
      _conceptoController.text = widget.egreso!.concepto;
      _valorController.text =
          UIHelpers.formatCurrency(widget.egreso!.valor.toDouble());
      _descripcionController.text = widget.egreso!.descripcion;

      // Convertimos el valor interno al valor mostrado
      _quincena = _quincenaToDisplay[widget.egreso!.quincena] ??
          widget.egreso!.quincena;

      // ✅ Verificamos que el valor cargado exista en la lista de opciones
      if (_quincena != null && !_quincenas.contains(_quincena)) {
        _quincena = null;
      }

      // ✅ Asignamos valores solo si no son nulos
      fechaPago = widget.egreso!.fechaPago;

      _fechaActual = widget.egreso!.fecha;

      _categoria = widget.egreso!.categoria;
      if (_categoria != null && !_categorias.contains(_categoria)) {
        _categoria = null;
      }

      _estado = widget.egreso!.estado;
      if (_estado != null && !_estados.contains(_estado)) {
        _estado = null;
      }
    }
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _valorController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _limpiarFormulario() {
    _conceptoController.clear();
    _valorController.clear();
    _descripcionController.clear();
    setState(() {
      _quincena = null;
      _categoria = null;
      _estado = null;
      fechaPago = DateTime.now();
    });
  }

  Future<void> _guardarEgreso() async {
    if (_formKey.currentState!.validate()) {
      if (_quincena == null || _categoria == null || _estado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, complete todos los campos')),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final String quincenaInterna =
            _displayToQuincena[_quincena!] ?? _quincena!;
        String valorLimpo =
            _valorController.text.replaceAll(RegExp(r'[^\d]'), '');
        if (valorLimpo.isEmpty) {
          UIHelpers.showErrorSnackBar(
            context: context,
            message: 'El valor no puede estar vacío',
          );
          return;
        }

        int valorNumerico = int.parse(valorLimpo);
        final egreso = Egreso(
          id: widget.egreso?.id ?? _generarIdAleatorio(),
          quincena: quincenaInterna,
          fecha: _fechaActual,
          fechaPago: fechaPago,
          categoria: _categoria!,
          concepto: _conceptoController.text,
          valor: valorNumerico,
          descripcion: _descripcionController.text,
          estado: _estado!,
        );

        final service = ref.read(egresoServiceProvider);
        if (widget.egreso == null) {
          await service.addEgreso(user.uid, egreso);
        } else {
          await service.actualizarEgreso(user.uid, egreso);
        }

        _limpiarFormulario();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado')),
        );
      }
    }
  }

  String _generarIdAleatorio() {
    const caracteres =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
        20, (index) => caracteres[random.nextInt(caracteres.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Themes.degradientLight,
      appBar: const AppBarFinances(
        title: 'Nuevo Egreso',
        showProfileIcon: false,
      ),
      body: Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildDropdown(_quincenas, _quincena, 'Periodo',
                        (val) => setState(() => _quincena = val)),
                    buildTextField(_conceptoController, 'Concepto'),
                    buildTextField(
                      _valorController,
                      'Valor',
                      isNumber: true,
                      inputFormatters: [CurrencyFormatterFromHelper()],
                    ),
                    buildTextField(
                      _descripcionController,
                      'Descripción',
                      isMultiline: true,
                    ),
                    buildDropdown(_categorias, _categoria, 'Categoría',
                        (val) => setState(() => _categoria = val)),
                    buildDropdown(_estados, _estado, 'Estado',
                        (val) => setState(() => _estado = val)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: fechaPago,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              fechaPago = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Fecha Pago',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child:
                              Text(DateFormat('dd/MM/yyyy').format(fechaPago)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _guardarEgreso,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Themes.primary,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Guardar',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDropdown<T>(
      List<T> items, T? value, String label, Function(T?) onChanged) {
    T? validValue = value;
    if (value != null && !items.contains(value)) {
      validValue = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<T>(
        initialValue: validValue,
        items: items
            .map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(item.toString()),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (val) => val == null ? 'Seleccione $label' : null,
      ),
    );
  }

  Widget buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    bool isMultiline = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          alignLabelWithHint: isMultiline,
        ),
        keyboardType: isNumber
            ? TextInputType.number
            : (isMultiline ? TextInputType.multiline : TextInputType.text),
        inputFormatters: inputFormatters,
        minLines: isMultiline ? 3 : 1,
        maxLines: isMultiline ? null : 1,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Ingrese $label';
          return null;
        },
      ),
    );
  }
}
