import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'package:intl/intl.dart'; // Importar paquete para formatear fechas
import 'dart:math'; // Para generar el ID aleatorio

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
  DateTime _fechaActual = DateTime.now(); // Variable para la fecha actual

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
      _fechaActual =
          widget.egreso!.fecha; // Cargar fecha desde el egreso si existe
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
          id: widget.egreso?.id ??
              _generarIdAleatorio(), // Generar ID aleatorio
          quincena: _quincena!,
          fecha: _fechaActual, // Guardar la fecha actual
          mes: _mes!,
          dia: _dia!,
          anio: _anio,
          categoria: _categoria!,
          concepto: _conceptoController.text,
          valor: int.parse(_valorController.text),
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

  // Generar un ID aleatorio
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
      appBar: AppBar(
        title: Text(widget.egreso == null ? 'Nuevo Egreso' : 'Editar Egreso'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _quincena,
                items: _quincenas.map((quincena) {
                  return DropdownMenuItem(
                    value: quincena,
                    child: Text(quincena),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _quincena = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Quincena'),
                validator: (value) {
                  if (value == null) {
                    return 'Por favor seleccione una quincena';
                  }
                  return null;
                },
              ),
              // Campo de Fecha Actual
              TextFormField(
                initialValue: DateFormat('dd/MM/yyyy').format(_fechaActual),
                decoration: const InputDecoration(labelText: 'Fecha Actual'),
                enabled: false, // Campo deshabilitado solo para mostrar
              ),
              DropdownButtonFormField<String>(
                value: _mes,
                items: _meses.map((mes) {
                  return DropdownMenuItem(
                    value: mes,
                    child: Text(mes),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _mes = value;
                    _actualizarDias();
                  });
                },
                decoration: const InputDecoration(labelText: 'Mes'),
                validator: (value) {
                  if (value == null) {
                    return 'Por favor seleccione un mes';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<int>(
                value: _dia,
                items: _dias.map((dia) {
                  return DropdownMenuItem(
                    value: dia,
                    child: Text(dia.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _dia = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Día'),
                validator: (value) {
                  if (value == null) {
                    return 'Por favor seleccione un día';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _conceptoController,
                decoration: const InputDecoration(labelText: 'Concepto'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un concepto';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(labelText: 'Valor'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un valor';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              DropdownButtonFormField<String>(
                value: _categoria,
                items: _categorias.map((categoria) {
                  return DropdownMenuItem(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoria = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Categoría'),
                validator: (value) {
                  if (value == null) {
                    return 'Por favor seleccione una categoría';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _estado,
                items: _estados.map((estado) {
                  return DropdownMenuItem(
                    value: estado,
                    child: Text(estado),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _estado = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Estado'),
                validator: (value) {
                  if (value == null) {
                    return 'Por favor seleccione un estado';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarEgreso,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
