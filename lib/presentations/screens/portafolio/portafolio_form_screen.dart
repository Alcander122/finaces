import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:finances/core/data/models/portafolio_model.dart';
import 'package:finances/core/data/services/portafolio_service.dart';

class PortafolioFormScreen extends StatefulWidget {
  final String userId;
  final Portafolio? portafolio;
  final List<String> categorias = const [
    'Criptomoneda',
    'Acciones',
    'Bonos',
    'Otros'
  ];
  final List<String> monedas = const ['USD', 'EUR', 'BTC', 'ETH'];

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
  final _valorController = TextEditingController();
  String? _selectedCategoria;
  String? _selectedMoneda;
  late DateTime _fechaCreacion;

  @override
  void initState() {
    super.initState();
    _fechaCreacion = widget.portafolio?.fechaCreacion ?? DateTime.now();
    _selectedCategoria = widget.portafolio?.categoria;
    _selectedMoneda = widget.portafolio?.moneda;

    if (widget.portafolio != null) {
      _nombreController.text = widget.portafolio!.nombre;
      _descripcionController.text = widget.portafolio!.descripcion ?? '';
      _valorController.text = widget.portafolio!.valor.toString();
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
        categoria: _selectedCategoria!,
        moneda: _selectedMoneda!,
        valor: double.parse(_valorController.text),
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
                controller: _valorController,
                decoration: const InputDecoration(labelText: "Valor*"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Campo obligatorio";
                  if (double.tryParse(value) == null) return "Valor inválido";
                  return null;
                },
              ),
              ListTile(
                title: const Text("Fecha de creación"),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaCreacion)),
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategoria,
                items: widget.categorias
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategoria = value),
                decoration: const InputDecoration(labelText: "Categoría*"),
                validator: (value) =>
                    value == null ? "Seleccione una categoría" : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedMoneda,
                items: widget.monedas
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedMoneda = value),
                decoration: const InputDecoration(labelText: "Moneda*"),
                validator: (value) =>
                    value == null ? "Seleccione una moneda" : null,
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
