import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/services/ingresos_service.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:intl/intl.dart';

List<String> categorias = [
  'Salario',
  'Bonificacion',
  'Ahorro',
  'Vacaciones',
  'Tranferencia',
  'Otros'
];

class IngresosScreen extends ConsumerStatefulWidget {
  @override
  _IngresosScreenState createState() => _IngresosScreenState();
}

class _IngresosScreenState extends ConsumerState<IngresosScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _editando = false;
  String? _ingresoEditadoId;

  final _fechaController = TextEditingController();
  final _conceptoController = TextEditingController();
  final _valorController = TextEditingController();
  final _notaController = TextEditingController();

  String? _mes, _quincena, _categoria;
  int? _anio, _dia;

  final IngresosService _ingresosService = IngresosService();

  @override
  void initState() {
    super.initState();
    _actualizarFechaActual();
  }

  void _actualizarFechaActual() {
    setState(() {
      _fechaController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    });
  }

  Future<void> _guardarIngreso() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(authProvider);
      if (user == null) return;

      Map<String, dynamic> ingreso = {
        'fecha': _fechaController.text,
        'mes': _mes,
        'dia': _dia,
        'anio': _anio,
        'quincena': _quincena,
        'categoria': _categoria,
        'concepto': _conceptoController.text,
        'valor': int.parse(_valorController.text),
        'nota': _notaController.text,
      };

      if (_editando && _ingresoEditadoId != null) {
        await _ingresosService.actualizarIngreso(
            user.uid, _ingresoEditadoId!, ingreso);
      } else {
        await _ingresosService.guardarIngreso(user.uid, ingreso);
      }
      _limpiarFormulario();
    }
  }

  void _editarIngreso(Map<String, dynamic> ingreso) {
    setState(() {
      _editando = true;
      _ingresoEditadoId = ingreso['id'];
      _fechaController.text = ingreso['fecha'];
      _mes = ingreso['mes'];
      _dia = ingreso['dia'];
      _anio = ingreso['anio'];
      _quincena = ingreso['quincena'];
      _categoria = ingreso['categoria'];
      _conceptoController.text = ingreso['concepto'];
      _valorController.text = ingreso['valor'].toString();
      _notaController.text = ingreso['nota'];
    });
  }

  Future<void> _eliminarIngreso(String ingresoId) async {
    final user = ref.read(authProvider);
    if (user == null) return;
    await _ingresosService.eliminarIngreso(user.uid, ingresoId);
    setState(() {}); // Actualizar la vista
  }

  void _limpiarFormulario() {
    setState(() {
      _editando = false;
      _ingresoEditadoId = null;
      _actualizarFechaActual();
      _conceptoController.clear();
      _valorController.clear();
      _notaController.clear();

      // Limpiar los campos seleccionables
      _mes = null;
      _quincena = null;
      _categoria = null;
      _anio = null;
      _dia = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user == null) return Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: Text('Ingresos')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(_editando ? 'Editar Ingreso' : 'Nuevo Ingreso'),
                content: _buildFormulario(),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar')),
                  ElevatedButton(
                      onPressed: _guardarIngreso, child: Text('Guardar')),
                ],
              ),
            ),
            child: Text(_editando ? 'Editar Ingreso' : 'Agregar Ingreso'),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _ingresosService.obtenerIngresos(user.uid).asStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());
                final ingresos = snapshot.data!;
                return ListView.builder(
                  itemCount: ingresos.length,
                  itemBuilder: (context, index) {
                    final ingreso = ingresos[index];
                    return ListTile(
                      title: Text(ingreso['concepto']),
                      subtitle:
                          Text('\$${ingreso['valor']} - ${ingreso['fecha']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _editarIngreso(ingreso)),
                          IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                await _eliminarIngreso(ingreso['id']);
                              }),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return SingleChildScrollView(
      // Solución al problema del desbordamiento
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
                controller: _fechaController,
                decoration: InputDecoration(labelText: 'Fecha')),
            DropdownButtonFormField<String>(
              value: _mes,
              hint: Text('Selecciona un mes'), // Sugerencia
              items: [
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
              ]
                  .map((mes) => DropdownMenuItem(value: mes, child: Text(mes)))
                  .toList(),
              onChanged: (value) => setState(() => _mes = value),
              decoration: InputDecoration(labelText: 'Mes'),
            ),
            DropdownButtonFormField<int>(
              value: _dia,
              hint: Text('Selecciona un día'), // Sugerencia
              items: List.generate(31, (index) => index + 1)
                  .map((dia) =>
                      DropdownMenuItem(value: dia, child: Text(dia.toString())))
                  .toList(),
              onChanged: (value) => setState(() => _dia = value),
              decoration: InputDecoration(labelText: 'Día'),
            ),
            DropdownButtonFormField<int>(
              value: _anio,
              hint: Text('Selecciona un año'), // Sugerencia
              items: List.generate(3, (index) => DateTime.now().year + index)
                  .map((anio) => DropdownMenuItem(
                      value: anio, child: Text(anio.toString())))
                  .toList(),
              onChanged: (value) => setState(() => _anio = value),
              decoration: InputDecoration(labelText: 'Año'),
            ),
            DropdownButtonFormField<String>(
              value: _quincena,
              hint: Text('Selecciona una quincena'), // Sugerencia
              items: ['Primera', 'Segunda']
                  .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                  .toList(),
              onChanged: (value) => setState(() => _quincena = value),
              decoration: InputDecoration(labelText: 'Quincena'),
            ),
            DropdownButtonFormField<String>(
              value: _categoria,
              hint: Text('Selecciona una categoría'), // Sugerencia
              items: categorias
                  .map((categoria) => DropdownMenuItem(
                      value: categoria, child: Text(categoria)))
                  .toList(),
              onChanged: (value) => setState(() => _categoria = value),
              decoration: InputDecoration(labelText: 'Categoría'),
            ),
            TextFormField(
                controller: _conceptoController,
                decoration: InputDecoration(labelText: 'Concepto')),
            TextFormField(
                controller: _valorController,
                decoration: InputDecoration(labelText: 'Valor'),
                keyboardType: TextInputType.number),
            TextFormField(
                controller: _notaController,
                decoration: InputDecoration(labelText: 'Nota')),
          ],
        ),
      ),
    );
  }
}
