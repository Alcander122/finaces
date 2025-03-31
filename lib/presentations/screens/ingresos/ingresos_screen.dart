import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/services/ingresos_service.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/utils/ingreso_validator.dart';
import 'package:finances/presentations/widgets/ingreso_table.dart';
import 'package:finances/presentations/widgets/Ingreso_chart.dart';
import 'package:intl/intl.dart';

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
  final IngresoValidator _validator = IngresoValidator();

  List<String> _camposVisibles = [
    'fecha',
    'mes',
    'anio',
    'quincena',
    'categoria',
    'concepto',
    'valor',
  ];

  @override
  void initState() {
    super.initState();
    _anio = DateTime.now().year;
    _mes = 'Enero';
    _quincena = 'Primera';
    _categoria = 'Salario';
    _dia = 1;
    _cargarIngresos();
  }

  Future<void> _cargarIngresos() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    List<Ingreso> ingresos =
        await _ingresosService.obtenerIngresos(authState.user!.uid);
    ingresos.sort((a, b) {
      if (a.anio != b.anio) {
        return a.anio!.compareTo(b.anio!);
      }
      return a.getMesNumero().compareTo(b.getMesNumero());
    });

    _ingresos = ingresos.map((ingreso) => ingreso.toMap()).toList();

    setState(() {});
  }

  Future<void> _guardarIngreso(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    final ingreso = Ingreso(
      id: _editId == null
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : _editId!,
      fecha: DateTime.now(),
      mes: _mes!,
      anio: _anio!,
      quincena: _quincena!,
      categoria: _categoria!,
      concepto: _conceptoController.text,
      valor: int.parse(_valorController.text),
    );

    try {
      if (_editId == null) {
        await _ingresosService.guardarIngreso(authState.user!.uid, ingreso);
      } else {
        await _ingresosService.actualizarIngreso(
            authState.user!.uid, _editId!, ingreso);
        _editId = null;
      }

      _cargarIngresos();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingreso guardado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar el ingreso')),
      );
    }
  }

  void _mostrarDialogo(BuildContext context,
      [Map<String, dynamic>? ingresoMap]) {
    if (ingresoMap != null) {
      _editId = ingresoMap['id'].toString();
      _mes = ingresoMap['mes'];
      _dia = ingresoMap['dia'];
      _anio = ingresoMap['anio'];
      _quincena = ingresoMap['quincena'];
      _categoria = ingresoMap['categoria'];
      _conceptoController.text = ingresoMap['concepto'];
      _valorController.text = ingresoMap['valor'].toString();
    } else {
      _editId = null;
      _conceptoController.clear();
      _valorController.clear();
      _notaController.clear();
    }

    // Agregar un pequeño delay para la apertura del diálogo
    Future.delayed(const Duration(milliseconds: 300), () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_editId == null ? 'Nuevo Ingreso' : 'Editar Ingreso'),
          content: SingleChildScrollView(
            child: _buildFormulario(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ElevatedButton(
                onPressed: () => _guardarIngreso(context),
                child: const Text('Guardar')),
          ],
        ),
      );
    });
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _mes,
            hint: const Text('Selecciona un mes'),
            items: const [
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
            decoration: const InputDecoration(labelText: 'Mes'),
            validator: (value) => _validator.validateMes(value),
          ),
          DropdownButtonFormField<int>(
            value: _dia,
            hint: const Text('Selecciona un día'),
            items: List.generate(31, (index) => index + 1)
                .map((dia) =>
                    DropdownMenuItem(value: dia, child: Text(dia.toString())))
                .toList(),
            onChanged: (value) => setState(() => _dia = value),
            decoration: const InputDecoration(labelText: 'Día'),
            validator: (value) => _validator.validateDia(value),
          ),
          DropdownButtonFormField<String>(
            value: _quincena,
            hint: const Text('Selecciona una quincena'),
            items: const ['Primera', 'Segunda']
                .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                .toList(),
            onChanged: (value) => setState(() => _quincena = value),
            decoration: const InputDecoration(labelText: 'Quincena'),
            validator: (value) => _validator.validateQuincena(value),
          ),
          DropdownButtonFormField<String>(
            value: _categoria,
            hint: const Text('Selecciona una categoría'),
            items: const [
              'Salario',
              'Bonificación',
              'Ahorro',
              'Vacaciones',
              'Transferencia',
              'Otros'
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (value) => setState(() => _categoria = value),
            decoration: const InputDecoration(labelText: 'Categoría'),
            validator: (value) => _validator.validateCategoria(value),
          ),
          TextFormField(
            controller: _conceptoController,
            decoration: const InputDecoration(labelText: 'Concepto'),
            validator: (value) => _validator.validateConcepto(value),
          ),
          TextFormField(
            controller: _valorController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Valor'),
            validator: (value) => _validator.validateValor(value),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarIngreso(String id) async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;
    await _ingresosService.eliminarIngreso(authState.user!.uid, id);
    _cargarIngresos();
  }

  void _mostrarDialogoSeleccionColumnas(BuildContext context) {
    Set<String> camposDisponibles = {};
    if (_ingresos.isNotEmpty) {
      camposDisponibles = _ingresos.first.keys.toSet();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Columnas'),
        content: SingleChildScrollView(
          child: Column(
            children: camposDisponibles
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
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () => _mostrarDialogoSeleccionColumnas(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gráfico de Dona para mostrar la distribución de ingresos por categoría
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: IncomeChart(
                ingresos: _ingresos
                    .map((ingreso) => Ingreso.fromMap(ingreso))
                    .toList(),
              ),
            ),
            // Tabla de ingresos
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IngresoTable(
                userID: user?.uid ?? '',
                ingresos: _ingresos,
                onEdit: (ingreso) => _mostrarDialogo(context, ingreso),
                onDelete: (id) => _eliminarIngreso(id),
                camposVisibles: _camposVisibles,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30.0, right: 30.0),
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('Nueva Transacción'),
          onPressed: () => _mostrarDialogo(context),
          backgroundColor: Colors.green,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
