import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/screens/Egreso/utils/thousands_formatter.dart';
import 'package:intl/intl.dart';
import 'dart:math';

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
  String? _mes;
  int? _dia;
  int _anio = DateTime.now().year;
  String? _categoria;
  String? _estado;
  DateTime _fechaActual = DateTime.now();

  final List<String> _quincenas = ['Primera', 'Segunda'];
  final List<String> _meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
  ];
  final List<String> _categorias = [
    'Salario',
    'Bonificacion',
    'Ahorro',
    'Vacaciones',
    'Tranferencia',
    'Otros'
  ];
  final List<String> _estados = ['Pendiente', 'Cancelado'];

  List<int> _dias = [];

  @override
  void initState() {
    super.initState();
    if (widget.egreso != null) {
      _conceptoController.text = widget.egreso!.concepto;
      _valorController.text = widget.egreso!.valor.toString();
      _descripcionController.text = widget.egreso!.descripcion;
      _quincena = widget.egreso!.quincena;
      _mes = widget.egreso!.mes;
      _dia = widget.egreso!.dia;
      _anio = widget.egreso!.anio;
      _categoria = widget.egreso!.categoria;
      _estado = widget.egreso!.estado;
      _fechaActual = widget.egreso!.fecha;
      _actualizarDias();
    }
  }

  void _actualizarDias() {
    if (_mes != null) {
      final int daysInMonth = DateTime(_anio, _meses.indexOf(_mes!) + 1, 0).day;
      setState(() {
        _dias = List<int>.generate(daysInMonth, (i) => i + 1);
      });
    } else {
      setState(() {
        _dias = [];
      });
    }
  }

  void _limpiarFormulario() {
    _conceptoController.clear();
    _valorController.clear();
    _descripcionController.clear();
    setState(() {
      _quincena = null;
      _mes = null;
      _dia = null;
      _categoria = null;
      _estado = null;
      _dias = [];
    });
  }

  Future<void> _guardarEgreso() async {
    if (_formKey.currentState!.validate()) {
      if (_quincena == null ||
          _mes == null ||
          _dia == null ||
          _categoria == null ||
          _estado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, complete todos los campos')),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final egreso = Egreso(
          id: widget.egreso?.id ?? _generarIdAleatorio(),
          quincena: _quincena!,
          fecha: _fechaActual,
          mes: _mes!,
          dia: _dia!,
          anio: _anio,
          categoria: _categoria!,
          concepto: _conceptoController.text,
          valor: int.parse(_valorController.text.replaceAll(',', '')),
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
                    buildDropdown(_quincenas, _quincena, 'Quincena',
                        (val) => setState(() => _quincena = val)),
                    buildReadonlyField('Fecha Actual',
                        DateFormat('dd/MM/yyyy').format(_fechaActual)),
                    buildDropdown(
                        _meses,
                        _mes,
                        'Mes',
                        (val) => setState(() {
                              _mes = val;
                              _actualizarDias();
                            })),
                    buildDropdown(_dias, _dia, 'Día',
                        (val) => setState(() => _dia = val)),
                    buildTextField(_conceptoController, 'Concepto'),
                    buildTextField(
                      _valorController,
                      'Valor',
                      isNumber: true,
                      inputFormatters: [ThousandsFormatter()],
                    ),
                    buildTextField(_descripcionController, 'Descripción'),
                    buildDropdown(_categorias, _categoria, 'Categoría',
                        (val) => setState(() => _categoria = val)),
                    buildDropdown(_estados, _estado, 'Estado',
                        (val) => setState(() => _estado = val)),
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
                            borderRadius: BorderRadius.circular(12),
                          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<T>(
        value: value,
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: inputFormatters,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Ingrese $label';
          return null;
        },
      ),
    );
  }

  Widget buildReadonlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        enabled: false,
      ),
    );
  }
}
