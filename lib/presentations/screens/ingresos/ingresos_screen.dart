// 📌 ingresos_screen.dart
// ============================================================================
// ARCHIVO: presentations/screens/ingresos/ingresos_screen.dart
// PROPÓSITO: Pantalla principal de ingresos
// ESTADO: CORREGIDO - Ahora sí guarda y actualiza ingresos correctamente
// ============================================================================

import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/presentations/screens/ingresos/Ingreso_form.dart'; // ← Asegúrate de que la ruta sea correcta
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:finances/presentations/widgets/reusable_cardtable.dart';
import 'package:finances/presentations/widgets/custom_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/services/ingresos_service.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/presentations/screens/ingresos/widgets/ingreso_table.dart';
import 'package:finances/presentations/screens/ingresos/widgets/ingreso_chart.dart';
import 'package:finances/presentations/screens/ingresos/widgets/paginator_widget.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';

class IngresosScreen extends ConsumerStatefulWidget {
  const IngresosScreen({super.key});

  @override
  IngresosScreenState createState() => IngresosScreenState();
}

class IngresosScreenState extends ConsumerState<IngresosScreen> {
  // ============================================================================
  // PROPIEDADES DEL ESTADO
  // ===========================================================================

  List<Map<String, dynamic>> _ingresos = [];
  String? _editId;
  int _currentPage = 1;
  int _itemsPerPage = 5;

  final IngresosService _ingresosService = IngresosService();

  final List<String> _camposVisibles = [
    'fechaIngreso',
    'categoria',
    'valor',
  ];

  // ============================================================================
  // CICLO DE VIDA
  // ============================================================================

  @override
  void initState() {
    super.initState();
    _cargarIngresos();
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final totalPages = (_ingresos.length / _itemsPerPage)
        .ceil()
        .clamp(1, double.infinity)
        .toInt();

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
              IncomeChart(
                ingresos: _ingresos.map((i) => Ingreso.fromMap(i)).toList(),
              ),
              const SizedBox(height: 16),
              ReusableCardTable(
                topColorStart: Themes.degradientDark,
                topColorEnd: Themes.degradientLight,
                child: IngresoTable(
                  userID: user.uid ?? '',
                  ingresos: _ingresos,
                  onEdit: (ingreso) => _mostrarDialogo(context, ingreso),
                  onDelete: (id) => _eliminarIngreso(id),
                  camposVisibles: _camposVisibles,
                  currentPage: _currentPage,
                  itemsPerPage: _itemsPerPage,
                ),
              ),
              const SizedBox(height: 12),
              PaginatorWidget(
                currentPage: _currentPage,
                totalPages: totalPages,
                itemsPerPage: _itemsPerPage,
                onPageChanged: (page) => setState(() => _currentPage = page),
                onItemsPerPageChanged: (value) {
                  setState(() {
                    _itemsPerPage = value;
                    _currentPage = 1;
                  });
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Nueva Transacción',
                      style: TextStyle(color: Colors.white)),
                  onPressed: () => _mostrarDialogo(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Themes.primary,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // OPERACIONES CON BASE DE DATOS
  // ============================================================================

  Future<void> _cargarIngresos() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    try {
      List<Ingreso> ingresos =
          await _ingresosService.obtenerIngresos(authState.user!.uid);
      ingresos.sort((a, b) => b.fechaIngreso.compareTo(a.fechaIngreso));
      setState(() {
        _ingresos = ingresos.map((i) => i.toMap()).toList();
      });
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(
            context: context, message: 'Error al cargar ingresos: $e');
      }
    }
  }

  Future<void> _guardarIngreso(Ingreso ingreso,
      {required BuildContext parentContext}) async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    try {
      if (_editId == null) {
        await _ingresosService.guardarIngreso(authState.user!.uid, ingreso);
      } else {
        await _ingresosService.actualizarIngreso(
            authState.user!.uid, _editId!, ingreso);
      }

      await _cargarIngresos();

      if (mounted) {
        Navigator.pop(context);
        Future.delayed(Duration.zero, () {
          if (mounted) {
            UIHelpers.showSuccessSnackBar(
              context: parentContext,
              message: _editId == null
                  ? 'Ingreso creado correctamente'
                  : 'Ingreso actualizado correctamente',
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(
            context: parentContext, message: 'Error al guardar el ingreso: $e');
      }
    }
  }

  Future<void> _eliminarIngreso(String id) async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    try {
      await _ingresosService.eliminarIngreso(authState.user!.uid, id);
      await _cargarIngresos();
      if (mounted) {
        UIHelpers.showSuccessSnackBar(
            context: context, message: 'Ingreso eliminado correctamente');
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(
            context: context, message: 'Error al eliminar el ingreso: $e');
      }
    }
  }

  // ============================================================================
  // DIÁLOGO DEL FORMULARIO - VERSIÓN CORREGIDA
  // ============================================================================

  void _mostrarDialogo(BuildContext context,
      [Map<String, dynamic>? ingresoMap]) {
    Ingreso? ingreso;
    if (ingresoMap != null) {
      ingreso = Ingreso.fromMap(ingresoMap);
      _editId = ingreso.id;
    } else {
      _editId = null;
    }

    // 🔹 CLAVE PARA ACCEDER AL MÉTODO submit() DEL FORMULARIO
    final GlobalKey<IngresoFromState> ingresoFormKey =
        GlobalKey<IngresoFromState>();

    // Clave requerida por CustomFormDialog para validación general
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => CustomFormDialog(
        title: _editId == null ? 'Nuevo Ingreso' : 'Editar Ingreso',
        formKey: dialogFormKey,
        onCancel: () => Navigator.pop(dialogContext),
        // 🔹 CORRECCIÓN CLAVE: Ahora sí se ejecuta el guardado
        onSave: () {
          if (dialogFormKey.currentState!.validate()) {
            // Llamamos al método submit() del formulario interno
            ingresoFormKey.currentState?.submit();
            // El submit() ejecutará onSave → _guardarIngreso → cierra diálogo y recarga
          }
        },
        children: [
          IngresoFrom(
            key: ingresoFormKey, // ← ¡Fundamental! Permite llamar a submit()
            ingreso: ingreso,
            onSave: (ing) => _guardarIngreso(ing, parentContext: context),
            onCancel: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // DIÁLOGO DE SELECCIÓN DE COLUMNAS
  // ============================================================================

  void _mostrarDialogoSeleccionColumnas(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar columnas'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var campo in [
                    'fechaIngreso',
                    'categoria',
                    'valor',
                    'concepto'
                  ])
                    CheckboxListTile(
                      title: Text(campo),
                      value: _camposVisibles.contains(campo),
                      onChanged: (value) {
                        setStateDialog(() {
                          if (value == true) {
                            _camposVisibles.add(campo);
                          } else {
                            _camposVisibles.remove(campo);
                          }
                        });
                        setState(() {}); // Actualiza la tabla principal
                      },
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
