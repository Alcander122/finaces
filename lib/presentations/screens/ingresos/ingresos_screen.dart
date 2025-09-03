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
import 'package:finances/core/data/utils/ui_helpers.dart';
// Importar UIHelpers

// Definición de la clase IngresosScreen que extiende ConsumerStatefulWidget
class IngresosScreen extends ConsumerStatefulWidget {
  const IngresosScreen({super.key});

  @override
  IngresosScreenState createState() => IngresosScreenState();
}

class IngresosScreenState extends ConsumerState<IngresosScreen> {
  // Controladores para los campos del formulario
  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _valorController = TextEditingController();
  final notaController = TextEditingController();
  final _fechaController = TextEditingController();

  // Variables para almacenar los ingresos y los filtros
  List<Map<String, dynamic>> _ingresos = [];
  String? _quincena, _categoria;
  String? _editId;
  DateTime _fechaIngreso = DateTime.now();

  // Instancias de servicios y validadores
  final IngresosService _ingresosService = IngresosService();
  final IngresoValidator _validator = IngresoValidator();

  // Lista de campos visibles en la tabla
  final List<String> _camposVisibles = [
    'fechaIngreso',
    'categoria',
    'valor',
  ];

  @override
  void initState() {
    super.initState();
    _quincena = 'Primera Quincena';
    _categoria = 'Salario';
    _fechaController.text = DateFormat('dd/MM/yyyy').format(_fechaIngreso);
    _cargarIngresos();
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _conceptoController.dispose();
    _valorController.dispose();
    notaController.dispose();
    super.dispose();
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
              // Gráfico de dona
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

  Future<void> _cargarIngresos() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    List<Ingreso> ingresos =
        await _ingresosService.obtenerIngresos(authState.user!.uid);

    ingresos.sort((a, b) => b.fechaIngreso.compareTo(a.fechaIngreso));

    _ingresos = ingresos.map((ingreso) => ingreso.toMap()).toList();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _guardarIngreso(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    // Manejo robusto del valor formateado
    String valorLimpo = _valorController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (valorLimpo.isEmpty) {
      UIHelpers.showErrorSnackBar(
        context: context,
        message: 'El valor no puede estar vacío',
      );
      return;
    }

    int valorNumerico = int.parse(valorLimpo);

    final ingreso = Ingreso(
      id: _editId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      fecha: DateTime.now(),
      fechaIngreso: _fechaIngreso,
      quincena: _quincena!,
      categoria: _categoria!,
      concepto: _conceptoController.text,
      valor: valorNumerico,
    );

    try {
      if (_editId == null) {
        await _ingresosService.guardarIngreso(authState.user!.uid, ingreso);
      } else {
        await _ingresosService.actualizarIngreso(
            authState.user!.uid, _editId!, ingreso);
      }

      await _cargarIngresos();
      Navigator.pop(context);
      UIHelpers.showSuccessSnackBarNew(
        context: context,
        message: _editId == null
            ? 'Ingreso creado correctamente'
            : 'Ingreso actualizado correctamente',
      );
    } catch (e) {
      UIHelpers.showErrorSnackBar(
        context: context,
        message: 'Error al guardar el ingreso: ${e.toString()}',
      );
    }
  }

  void _mostrarDialogo(BuildContext context,
      [Map<String, dynamic>? ingresoMap]) {
    _resetFormulario();

    if (ingresoMap != null) {
      final ingreso = Ingreso.fromMap(ingresoMap);
      _editId = ingreso.id;
      _fechaIngreso = ingreso.fechaIngreso;
      _fechaController.text =
          DateFormat('dd/MM/yyyy').format(ingreso.fechaIngreso);
      _quincena = ingreso.quincena;
      _categoria = ingreso.categoria;
      _conceptoController.text = ingreso.concepto;

      // Asegurar formato correcto al editar
      _valorController.text =
          UIHelpers.formatCurrency(ingreso.valor.toDouble());

      // Forzar actualización visual
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      _editId = null;
      _fechaIngreso = DateTime.now();
      _fechaController.text = DateFormat('dd/MM/yyyy').format(_fechaIngreso);
    }

    // SOLUCIÓN DEFINITIVA #1: Diálogo sin desbordamiento usando LayoutBuilder
    showDialog(
      context: context,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          // Calcular el ancho máximo disponible para el diálogo
          double maxWidth = constraints.maxWidth * 0.9;
          if (maxWidth > 500) maxWidth = 500; // Límite máximo

          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: AlertDialog(
              title: Text(_editId == null ? 'Nuevo Ingreso' : 'Editar Ingreso'),
              content: _buildFormulario(),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => _guardarIngreso(context),
                  child: const Text('Guardar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _resetFormulario() {
    _editId = null;
    _fechaIngreso = DateTime.now();
    _fechaController.text = DateFormat('dd/MM/yyyy').format(_fechaIngreso);
    _quincena = 'Primera Quincena';
    _categoria = 'Salario';
    _conceptoController.clear();
    _valorController.clear();
  }

  // Método para construir el formulario de ingresos
  Widget _buildFormulario() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular el ancho máximo para los campos
        double fieldMaxWidth =
            constraints.maxWidth * 0.9; // 90% del ancho disponible

        return SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Campo de Fecha Ingreso
                _buildFieldContainer(
                  fieldMaxWidth,
                  TextFormField(
                    controller: _fechaController,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fechaIngreso,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _fechaIngreso = picked;
                          _fechaController.text =
                              DateFormat('dd/MM/yyyy').format(picked);
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Fecha Ingreso',
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Campo de Quincena
                _buildFieldContainer(
                  fieldMaxWidth,
                  DropdownButtonFormField<String>(
                    value: _quincena,
                    hint: const Text('Selecciona una quincena'),
                    items: const [
                      'Primera Quincena',
                      'Segunda Quincena',
                      'Diario',
                      'Mensual'
                    ]
                        .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                        .toList(),
                    onChanged: (value) => setState(() => _quincena = value),
                    decoration: InputDecoration(
                      labelText: 'Periodo',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10),
                    ),
                    validator: _validator.validateQuincena,
                    isExpanded: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Campo de Categoría
                _buildFieldContainer(
                  fieldMaxWidth,
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
                    ]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) => setState(() => _categoria = value),
                    decoration: InputDecoration(
                      labelText: 'Categoría',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10),
                    ),
                    validator: _validator.validateCategoria,
                    isExpanded: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Campo de Concepto
                _buildFieldContainer(
                  fieldMaxWidth,
                  TextFormField(
                    controller: _conceptoController,
                    keyboardType: TextInputType.multiline,
                    minLines: 3,
                    maxLines: null,
                    decoration: const InputDecoration(
                      labelText: 'Concepto',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    ),
                    validator: _validator.validateConcepto,
                  ),
                ),
                const SizedBox(height: 12),

                // SOLUCIÓN DEFINITIVA: Campo de Valor con ancho fijo
                _buildValorField(fieldMaxWidth),
              ],
            ),
          ),
        );
      },
    );
  }

// SOLUCIÓN DEFINITIVA #1: Campo de Valor con ancho controlado
  Widget _buildValorField(double maxWidth) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(
        width: double.infinity,
        child: TextFormField(
          controller: _valorController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Valor',
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          ),
          onChanged: (value) {
            // Eliminar caracteres no numéricos
            String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');

            if (cleanValue.isEmpty) {
              _valorController.text = '';
              return;
            }

            // Convertir a número y formatear
            int number = int.parse(cleanValue);
            String formatted = UIHelpers.formatCurrency(number.toDouble());

            // Actualizar solo si el valor formateado es diferente
            if (formatted != _valorController.text) {
              // Calcular posición del cursor
              int cursorPosition = value.length - cleanValue.length;

              _valorController.text = formatted;
              _valorController.selection = TextSelection.collapsed(
                  offset: formatted.length - cursorPosition);
            }
          },
          validator: (value) {
            // Validar usando el valor limpio
            String cleanValue = value?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
            return _validator
                .validateValor(cleanValue.isEmpty ? null : cleanValue);
          },
        ),
      ),
    );
  }

// Contenedor universal para campos sin desbordamiento
  Widget _buildFieldContainer(double maxWidth, Widget child) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );
  }

  Future<void> _eliminarIngreso(String id) async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content:
            const Text('¿Estás seguro de que deseas eliminar este ingreso?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _ingresosService.eliminarIngreso(authState.user!.uid, id);
        await _cargarIngresos();
        UIHelpers.showSuccessSnackBarNew(
          context: context,
          message: 'Ingreso eliminado correctamente',
        );
      } catch (e) {
        UIHelpers.showErrorSnackBar(
          context: context,
          message: 'Error al eliminar el ingreso',
        );
      }
    }
  }

  void _mostrarDialogoSeleccionColumnas(BuildContext context) {
    Set<String> camposDisponibles = {};
    if (_ingresos.isNotEmpty) {
      camposDisponibles = _ingresos.first.keys.toSet();
    }
    camposDisponibles
      ..remove('id')
      ..remove('fecha');

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
                              campo == 'fechaIngreso'
                                  ? 'Fecha Ingreso'
                                  : campo == 'quincena'
                                      ? 'Periodo'
                                      : campo,
                            ),
                            value: _camposVisibles.contains(campo),
                            onChanged: (value) {
                              setStateDialog(() {
                                if (value == true) {
                                  _camposVisibles.add(campo);
                                } else {
                                  _camposVisibles.remove(campo);
                                }
                              });
                              if (mounted) {
                                setState(() {});
                              }
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
