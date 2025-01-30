import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/core/data/services/egreso_service.dart';

class EgresoForm extends ConsumerStatefulWidget {
  final Egreso? egreso; // Agregar el parámetro egreso

  const EgresoForm({Key? key, this.egreso})
      : super(key: key); // Modificar el constructor

  @override
  ConsumerState<EgresoForm> createState() => _EgresoFormState();
}

class _EgresoFormState extends ConsumerState<EgresoForm> {
  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _valorController = TextEditingController();
  final _descripcionController = TextEditingController();

  String _quincena = 'Primera';
  String _mes = 'Enero';
  int _dia = 1;
  int _anio = DateTime.now().year;
  String _categoria = 'Comida';
  String _estado = 'Pendiente';

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
  }

  Future<void> _guardarEgreso() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final egreso = Egreso(
          id: widget.egreso?.id ?? DateTime.now().toString(),
          quincena: _quincena,
          fecha: DateTime.now(),
          mes: _mes,
          dia: _dia,
          anio: _anio,
          categoria: _categoria,
          concepto: _conceptoController.text,
          valor: int.parse(_valorController.text),
          descripcion: _descripcionController.text,
          estado: _estado,
        );

        final service = ref.read(egresoServiceProvider);
        if (widget.egreso != null) {
          await service.actualizarEgreso(user.uid, egreso);
        } else {
          await service.addEgreso(user.uid, egreso);
        }

        _limpiarFormulario();
        Navigator.pop(context);
      } else {
        // Manejar el caso en el que el usuario no esté autenticado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Egreso'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Campos del formulario (quincena, mes, día, año, etc.)
              // ...
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
