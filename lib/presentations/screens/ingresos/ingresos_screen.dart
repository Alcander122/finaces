// Importaciones necesarias para la pantalla de ingresos
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:finances/presentations/widgets/reusable_cardtable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/services/ingresos_service.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/utils/ingreso_validator.dart';
import 'package:finances/presentations/screens/ingresos/widgets/ingreso_table.dart';
import 'package:finances/presentations/screens/ingresos/widgets/Ingreso_chart.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:intl/intl.dart'; // Para formatear fechas

// Definición de la clase IngresosScreen que extiende ConsumerStatefulWidget
class IngresosScreen extends ConsumerStatefulWidget {
  const IngresosScreen({super.key});

  // Método que crea el estado de la pantalla
  @override
  IngresosScreenState createState() => IngresosScreenState();
}

// Clase que maneja el estado de la pantalla de ingresos
class IngresosScreenState extends ConsumerState<IngresosScreen> {
  // Controladores para los campos del formulario
  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _valorController = TextEditingController();
  final notaController = TextEditingController();

  // Variables para almacenar los ingresos y los filtros
  List<Map<String, dynamic>> _ingresos = [];
  String? _quincena, _categoria;
  String? _editId;
  DateTime _fechaIngreso = DateTime.now(); // Nuevo campo

  // Instancias de servicios y validadores
  final IngresosService _ingresosService = IngresosService();
  final IngresoValidator _validator = IngresoValidator();

  // Lista de campos visibles en la tabla (sin 'mes' y 'anio')
  final List<String> _camposVisibles = [
    'fechaIngreso', // Reemplaza 'fecha', 'mes', 'anio'
    'quincena',
    'categoria',
    'concepto',
    'valor',
  ];

  // Método que se ejecuta al inicializar la pantalla
  @override
  void initState() {
    super.initState();
    _quincena = 'Primera';
    _categoria = 'Salario';
    _cargarIngresos();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: Themes.light,
      appBar: AppBarFinances(
        title: 'Ingresos',
        showProfileIcon: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.view_list),
            color: Colors.white,
            onPressed: () => _mostrarDialogoSeleccionColumnas(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gráfico de dona (restaurado)
              IncomeChart(
                ingresos: _ingresos
                    .map((ingreso) => Ingreso.fromMap(ingreso))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // WIDGET TARJETA REUTILIZABLE
              ReusableCardTable(
                topColorStart: Themes.degradientDark,
                topColorEnd: Themes.degradientLight,
                child: IngresoTable(
                  userID: user.uid ?? '',
                  ingresos: _ingresos,
                  onEdit: (ingreso) => _mostrarDialogo(context, ingreso),
                  onDelete: (id) => _eliminarIngreso(id),
                  camposVisibles: _camposVisibles,
                ),
              ),

              // Botón debajo del contenido
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Nueva Transacción',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () => _mostrarDialogo(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Themes.primary,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // Cargar ingresos desde el servicio
  Future<void> _cargarIngresos() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    // Obtener los ingresos del servicio
    List<Ingreso> ingresos =
        await _ingresosService.obtenerIngresos(authState.user!.uid);

    // Ordenar los ingresos por fechaIngreso
    ingresos.sort((a, b) => b.fechaIngreso.compareTo(a.fechaIngreso));

    // Convertir los ingresos a un formato compatible con la tabla
    _ingresos = ingresos.map((ingreso) => ingreso.toMap()).toList();

    // Actualizar el estado para reflejar los cambios
    setState(() {});
  }

  // Método para guardar un ingreso
  Future<void> _guardarIngreso(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    // Crear el objeto Ingreso con los datos del formulario
    final ingreso = Ingreso(
      id: _editId == null
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : _editId!,
      fecha: DateTime.now(), // Legacy
      fechaIngreso: _fechaIngreso, // Nuevo campo
      quincena: _quincena!,
      categoria: _categoria!,
      concepto: _conceptoController.text,
      valor: int.parse(_valorController.text),
    );

    try {
      // Guardar o actualizar el ingreso en el servicio
      if (_editId == null) {
        await _ingresosService.guardarIngreso(authState.user!.uid, ingreso);
      } else {
        await _ingresosService.actualizarIngreso(
            authState.user!.uid, _editId!, ingreso);
        _editId = null;
      }

      // Recargar los ingresos y mostrar un mensaje
      _cargarIngresos();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingreso guardado correctamente')),
      );
    } catch (e) {
      // Mostrar un mensaje de error si ocurre algún problema
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar el ingreso')),
      );
    }
  }

  // Método para mostrar el diálogo de edición de ingresos
  void _mostrarDialogo(BuildContext context,
      [Map<String, dynamic>? ingresoMap]) {
    if (ingresoMap != null) {
      // Poblar los campos del formulario con los datos del ingreso
      final ingreso = Ingreso.fromMap(ingresoMap);
      _editId = ingreso.id;
      _fechaIngreso = ingreso.fechaIngreso;
      _quincena = ingreso.quincena;
      _categoria = ingreso.categoria;
      _conceptoController.text = ingreso.concepto;
      _valorController.text = ingreso.valor.toString();
    } else {
      // Limpiar los campos del formulario
      _editId = null;
      _fechaIngreso = DateTime.now();
      _conceptoController.clear();
      _valorController.clear();
    }

    // Mostrar el diálogo después de un pequeño delay
    Future.delayed(const Duration(milliseconds: 300), () {
      showDialog(
        // ignore: use_build_context_synchronously
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

// Método para construir el formulario de ingresos
  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Campo para seleccionar la fecha con estilo consistente
          TextFormField(
            readOnly: true,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _fechaIngreso,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _fechaIngreso = picked);
              }
            },
            decoration: InputDecoration(
              labelText: 'Fecha Ingreso',
              suffixIcon: const Icon(Icons.calendar_today),
              border: const OutlineInputBorder(),
            ),
            controller: TextEditingController(
              text: DateFormat('dd/MM/yyyy').format(_fechaIngreso),
            ),
          ),

          const SizedBox(height: 12),

          // Campo para seleccionar la quincena
          DropdownButtonFormField<String>(
            value: _quincena,
            hint: const Text('Selecciona una quincena'),
            items: const ['Primera', 'Segunda']
                .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                .toList(),
            onChanged: (value) => setState(() => _quincena = value),
            decoration: const InputDecoration(
              labelText: 'Quincena',
              border: OutlineInputBorder(),
            ),
            validator: (value) => _validator.validateQuincena(value),
          ),

          const SizedBox(height: 12),

          // Campo para seleccionar la categoría
          DropdownButtonFormField<String>(
            value: _categoria,
            hint: const Text('Selecciona una categoría'),
            items: const [
              'Salario',
              'Bonificación',
              'Reembolso',
              'Intereses',
              'Devolución',
              'Transferencia',
              'Otros'
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (value) => setState(() => _categoria = value),
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
            ),
            validator: (value) => _validator.validateCategoria(value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _conceptoController,
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Concepto',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            validator: (value) => _validator.validateConcepto(value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _valorController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Valor',
              border: OutlineInputBorder(),
            ),
            validator: (value) => _validator.validateValor(value),
          ),
        ],
      ),
    );
  }

  // Método para eliminar un ingreso
  Future<void> _eliminarIngreso(String id) async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;
    await _ingresosService.eliminarIngreso(authState.user!.uid, id);
    _cargarIngresos();
  }

  // Método para mostrar el diálogo de selección de columnas
  void _mostrarDialogoSeleccionColumnas(BuildContext context) {
    Set<String> camposDisponibles = {};
    if (_ingresos.isNotEmpty) {
      camposDisponibles = _ingresos.first.keys.toSet();
    }
    // Excluir 'id' de los campos disponibles
    camposDisponibles.remove('id');
    camposDisponibles.remove('fecha'); // Excluir 'fecha' si no se usa

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Seleccionar Columnas'),
              content: SingleChildScrollView(
                child: Column(
                  children: camposDisponibles
                      .map((campo) => CheckboxListTile(
                            title: Text(
                              campo == 'fechaIngreso' ? 'Fecha Ingreso' : campo,
                            ),
                            value: _camposVisibles.contains(campo),
                            onChanged: (value) {
                              setStateDialog(() {
                                if (value!) {
                                  _camposVisibles.add(campo);
                                } else {
                                  _camposVisibles.remove(campo);
                                }
                              });
                              setState(() {});
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
            );
          },
        );
      },
    );
  }
}
