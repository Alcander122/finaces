import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:finances/core/data/models/portafolio_model.dart';
import 'package:finances/core/data/services/portafolio_service.dart';

class PortafolioFormScreen extends StatefulWidget {
  final String userId;
  final Portafolio? portafolio;

  const PortafolioFormScreen({
    super.key,
    required this.userId,
    this.portafolio,
  });

  @override
  _PortafolioFormScreenState createState() => _PortafolioFormScreenState();
}

class _PortafolioFormScreenState extends State<PortafolioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _notaController = TextEditingController();
  late DateTime _fechaCreacion;

  @override
  void initState() {
    super.initState();
    _fechaCreacion = widget.portafolio?.fechaCreacion ?? DateTime.now();

    if (widget.portafolio != null) {
      _nombreController.text = widget.portafolio!.nombre;
      _descripcionController.text = widget.portafolio!.descripcion ?? '';
      _notaController.text = widget.portafolio!.nota;
    }
  }

  void _guardarPortafolio() {
    if (_formKey.currentState!.validate()) {
      final portafolio = Portafolio(
        id: widget.portafolio?.id ?? const Uuid().v4(),
        userId: widget.userId,
        nombre: _nombreController.text,
        descripcion: _descripcionController.text.isNotEmpty
            ? _descripcionController.text
            : null,
        fechaCreacion: _fechaCreacion,
        nota: _notaController.text,
      );

      if (widget.portafolio == null) {
        PortafolioService().agregarPortafolio(widget.userId, portafolio);
      } else {
        PortafolioService().actualizarPortafolio(widget.userId, portafolio);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.portafolio == null
            ? "Nuevo Portafolio"
            : "Editar Portafolio"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: "Nombre*"),
                validator: (value) =>
                    value!.isEmpty ? "Campo obligatorio" : null,
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: "Descripción"),
              ),
              TextFormField(
                controller: _notaController,
                decoration: const InputDecoration(labelText: "Nota*"),
                validator: (value) =>
                    value!.isEmpty ? "Campo obligatorio" : null,
              ),
              ListTile(
                title: const Text("Fecha de creación"),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaCreacion)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarPortafolio,
                child: const Text("Guardar Portafolio"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
