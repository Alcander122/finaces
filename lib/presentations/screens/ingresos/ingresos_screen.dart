import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/services/ingresos_service.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:finances/presentations/widgets/ingreso_table.dart';

class IngresosScreen extends ConsumerStatefulWidget {
  const IngresosScreen({super.key});

  @override
  _IngresosScreenState createState() => _IngresosScreenState();
}

class _IngresosScreenState extends ConsumerState<IngresosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _valorController = TextEditingController();
  final _notaController = TextEditingController();

  List<Map<String, dynamic>> _ingresos = [];
  String? _mes, _quincena, _categoria;
  int? _anio, _dia;
  String? _editId;

  final IngresosService _ingresosService = IngresosService();

  List<String> _camposVisibles = [
    'fecha',
    'mes',
    'dia',
    'anio',
    'quincena',
    'categoria',
    'concepto',
    'valor',
    'nota'
  ];

  @override
  void initState() {
    super.initState();
    _anio = DateTime.now().year;
    _mes = 'Enero'; // Valor inicial predeterminado
    _quincena = 'Primera'; // Valor inicial predeterminado
    _categoria = 'Salario'; // Valor inicial predeterminado
    _dia = 1; // Día inicial predeterminado
    _cargarIngresos();
  }

  Future<void> _cargarIngresos() async {
    final user = ref.read(authProvider);
    if (user == null) return;

    _ingresos = await _ingresosService.obtenerIngresos(user.uid);
    _ingresos.sort((a, b) {
      final anioA = a['anio'] ?? 0;
      final anioB = b['anio'] ?? 0;
      final mesA = _mesToNumber(a['mes'] ?? '');
      final mesB = _mesToNumber(b['mes'] ?? '');

      if (anioA != anioB) {
        return anioA.compareTo(anioB);
      }
      return mesA.compareTo(mesB);
    });

    setState(() {});
  }

  int _mesToNumber(String mes) {
    const meses = [
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
    return meses.indexOf(mes) + 1;
  }

  Future<void> _guardarIngreso(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(authProvider);
      if (user == null) return;

      Map<String, dynamic> ingreso = {
        'fecha': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'mes': _mes,
        'dia': _dia,
        'anio': _anio,
        'quincena': _quincena,
        'categoria': _categoria,
        'concepto': _conceptoController.text,
        'valor': int.parse(_valorController.text),
        'nota': _notaController.text,
      };

      if (_editId == null) {
        await _ingresosService.guardarIngreso(user.uid, ingreso);
      } else {
        await _ingresosService.actualizarIngreso(user.uid, _editId!, ingreso);
        _editId = null;
      }

      _cargarIngresos();
      Navigator.pop(context);
    }
  }

  void _mostrarDialogo(BuildContext context, [Map<String, dynamic>? ingreso]) {
    if (ingreso != null) {
      _editId = ingreso['id'];
      _mes = ingreso['mes'];
      _dia = ingreso['dia'];
      _anio = ingreso['anio'];
      _quincena = ingreso['quincena'];
      _categoria = ingreso['categoria'];
      _conceptoController.text = ingreso['concepto'];
      _valorController.text = ingreso['valor'].toString();
      _notaController.text = ingreso['nota'];
    } else {
      _editId = null;
      _conceptoController.clear();
      _valorController.clear();
      _notaController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editId == null ? 'Nuevo Ingreso' : 'Editar Ingreso'),
        content: SingleChildScrollView(
          child: _buildFormulario(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          ElevatedButton(
              onPressed: () => _guardarIngreso(context),
              child: Text('Guardar')),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _mes,
            hint: Text('Selecciona un mes'),
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
            hint: Text('Selecciona un día'),
            items: List.generate(31, (index) => index + 1)
                .map((dia) =>
                    DropdownMenuItem(value: dia, child: Text(dia.toString())))
                .toList(),
            onChanged: (value) => setState(() => _dia = value),
            decoration: InputDecoration(labelText: 'Día'),
          ),
          DropdownButtonFormField<String>(
            value: _quincena,
            hint: Text('Selecciona una quincena'),
            items: ['Primera', 'Segunda']
                .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                .toList(),
            onChanged: (value) => setState(() => _quincena = value),
            decoration: InputDecoration(labelText: 'Quincena'),
          ),
          DropdownButtonFormField<String>(
            value: _categoria,
            hint: Text('Selecciona una categoría'),
            items: [
              'Salario',
              'Bonificacion',
              'Ahorro',
              'Vacaciones',
              'Tranferencia',
              'Otros'
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (value) => setState(() => _categoria = value),
            decoration: InputDecoration(labelText: 'Categoría'),
          ),
          TextFormField(
            controller: _conceptoController,
            decoration: InputDecoration(labelText: 'Concepto'),
          ),
          TextFormField(
            controller: _valorController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Valor'),
          ),
          TextFormField(
            controller: _notaController,
            decoration: InputDecoration(labelText: 'Nota'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarIngreso(String id) async {
    final user = ref.read(authProvider);
    if (user == null) return;
    await _ingresosService.eliminarIngreso(user.uid, id);
    _cargarIngresos();
  }

  void _mostrarDialogoSeleccionColumnas(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seleccionar Columnas'),
        content: SingleChildScrollView(
          child: Column(
            children: _camposVisibles
                .map((campo) => CheckboxListTile(
                      title: Text(campo),
                      value: _camposVisibles.contains(campo),
                      onChanged: (value) {
                        setState(() {
                          if (value!) {
                            _camposVisibles.add(campo);
                          } else {
                            _camposVisibles.remove(campo);
                          }
                        });
                      },
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    return Scaffold(
<<<<<<< HEAD
      appBar: AppBar(
        title: Text('Ingresos'),
        actions: [
          IconButton(
            icon: Icon(Icons.view_list),
            onPressed: () => _mostrarDialogoSeleccionColumnas(context),
=======
      appBar: AppBar(title: Text('Ingresos')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              _limpiarFormulario();
              _mostrarDialogo(context);
            },
            child: Text('Agregar Ingreso'),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _ingresosService.obtenerIngresos(user.uid).asStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
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
                            onPressed: () {
                              _editarIngreso(ingreso);
                              _mostrarDialogo(context);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              await _eliminarIngreso(ingreso['id']);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
>>>>>>> d251a602acd46738823f2be3fca9c2d66ce3e325
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IngresoTable(
          userID: user?.uid ?? '',
          ingresos: _ingresos,
          onEdit: (ingreso) => _mostrarDialogo(context, ingreso),
          onDelete: (id) => _eliminarIngreso(id),
          camposVisibles: _camposVisibles,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogo(context),
        child: Icon(Icons.add),
      ),
    );
  }
}
