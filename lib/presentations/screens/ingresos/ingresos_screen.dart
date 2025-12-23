// 📌 ingresos_screen.dart
// ============================================================================
// ARCHIVO: presentations/screens/ingresos/ingresos_screen.dart
// PROPÓSITO: Pantalla principal de ingresos
// DESCRIPCIÓN: Muestra tabla de ingresos, gráfico y formulario en diálogo full-screen
// ============================================================================

import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/presentations/screens/ingresos/Ingreso_form.dart';
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

  /// Lista de ingresos cargados desde la base de datos
  List<Map<String, dynamic>> _ingresos = [];

  /// ID del ingreso siendo editado (null si es nuevo)
  String? _editId;

  // ========== PAGINACIÓN ==========
  /// Página actual de la tabla
  int _currentPage = 1;

  /// Cantidad de items por página
  int _itemsPerPage = 5;

  // ========== SERVICIOS ==========
  /// Servicio para operaciones con ingresos
  final IngresosService _ingresosService = IngresosService();

  // ========== CONFIGURACIÓN DE TABLA ==========
  /// Campos visibles en la tabla
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
    // Cargar ingresos al iniciar la pantalla
    _cargarIngresos();
  }

  // ============================================================================
  // BUILD - ESTRUCTURA PRINCIPAL
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    // Obtener usuario autenticado
    final user = ref.watch(authProvider);

    // Calcular total de páginas
    final totalPages = (_ingresos.length / _itemsPerPage)
        .ceil()
        .clamp(1, double.infinity)
        .toInt();

    return Scaffold(
      backgroundColor: Themes.light,

      // ========== APP BAR ==========
      appBar: AppBarFinances(
        title: 'Ingresos',
        showProfileIcon: false,
        actions: [
          // Botón para seleccionar columnas visibles
          IconButton(
            icon: const Icon(Icons.view_list),
            color: Colors.white,
            onPressed: () => _mostrarDialogoSeleccionColumnas(context),
          ),
        ],
      ),

      // ========== CUERPO PRINCIPAL ==========
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== SECCIÓN 1: GRÁFICO DE DONA ==========
              IncomeChart(
                ingresos: _ingresos
                    .map((ingreso) => Ingreso.fromMap(ingreso))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // ========== SECCIÓN 2: TABLA DE INGRESOS ==========
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

              // ========== SECCIÓN 3: PAGINADOR ==========
              PaginatorWidget(
                currentPage: _currentPage,
                totalPages: totalPages,
                itemsPerPage: _itemsPerPage,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                onItemsPerPageChanged: (value) {
                  setState(() {
                    _itemsPerPage = value;
                    _currentPage = 1; // Reset a primera página
                  });
                },
              ),

              const SizedBox(height: 24),

              // ========== SECCIÓN 4: BOTÓN NUEVA TRANSACCIÓN ==========
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
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // 📡 OPERACIONES CON BASE DE DATOS
  // ============================================================================

  /// Carga todos los ingresos del usuario desde la base de datos
  ///
  /// Proceso:
  /// 1. Obtiene el usuario autenticado
  /// 2. Carga ingresos desde Firestore
  /// 3. Ordena por fecha descendente (más recientes primero)
  /// 4. Actualiza el estado
  Future<void> _cargarIngresos() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    try {
      // Obtener ingresos del servicio
      List<Ingreso> ingresos =
          await _ingresosService.obtenerIngresos(authState.user!.uid);

      // Ordenar por fecha descendente (más recientes primero)
      ingresos.sort((a, b) => b.fechaIngreso.compareTo(a.fechaIngreso));

      // Actualizar estado
      setState(() {
        _ingresos = ingresos.map((ingreso) => ingreso.toMap()).toList();
      });
    } catch (e) {
      // Mostrar error si falla la carga
      if (mounted) {
        UIHelpers.showErrorSnackBar(
          context: context,
          message: 'Error al cargar ingresos: $e',
        );
      }
    }
  }

  /// Guarda o actualiza un ingreso
  ///
  /// Parámetros:
  /// - ingreso: Objeto Ingreso a guardar
  /// - parentContext: Contexto para mostrar mensajes
  ///
  /// Proceso:
  /// 1. Valida que el usuario esté autenticado
  /// 2. Si es nuevo: guarda en Firestore
  /// 3. Si es edición: actualiza en Firestore
  /// 4. Recarga la lista de ingresos
  /// 5. Cierra el diálogo
  /// 6. Muestra mensaje de éxito
  Future<void> _guardarIngreso(Ingreso ingreso,
      {required BuildContext parentContext}) async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    try {
      // Verificar si es nuevo o edición
      if (_editId == null) {
        // Guardar nuevo ingreso
        await _ingresosService.guardarIngreso(authState.user!.uid, ingreso);
      } else {
        // Actualizar ingreso existente
        await _ingresosService.actualizarIngreso(
            authState.user!.uid, _editId!, ingreso);
      }

      // Recargar la lista de ingresos
      await _cargarIngresos();

      // Cerrar el diálogo si está montado
      if (mounted) {
        Navigator.pop(context);

        // Mostrar mensaje de éxito en el siguiente frame
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
      // Mostrar error si falla el guardado
      if (mounted) {
        Future.delayed(Duration.zero, () {
          if (mounted) {
            UIHelpers.showErrorSnackBar(
              context: parentContext,
              message: 'Error al guardar el ingreso: $e',
            );
          }
        });
      }
    }
  }

  /// Elimina un ingreso de la base de datos
  ///
  /// Parámetros:
  /// - id: ID del ingreso a eliminar
  ///
  /// Proceso:
  /// 1. Obtiene el usuario autenticado
  /// 2. Elimina el ingreso de Firestore
  /// 3. Recarga la lista de ingresos
  /// 4. Muestra mensaje de éxito
  Future<void> _eliminarIngreso(String id) async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    try {
      // Eliminar ingreso del servicio
      await _ingresosService.eliminarIngreso(authState.user!.uid, id);

      // Recargar la lista de ingresos
      await _cargarIngresos();

      // Mostrar mensaje de éxito
      if (mounted) {
        Future.delayed(Duration.zero, () {
          if (mounted) {
            UIHelpers.showSuccessSnackBar(
              context: context,
              message: 'Ingreso eliminado correctamente',
            );
          }
        });
      }
    } catch (e) {
      // Mostrar error si falla la eliminación
      if (mounted) {
        Future.delayed(Duration.zero, () {
          if (mounted) {
            UIHelpers.showErrorSnackBar(
              context: context,
              message: 'Error al eliminar el ingreso: $e',
            );
          }
        });
      }
    }
  }

  // ============================================================================
  // 🎯 DIÁLOGOS
  // ============================================================================

  /// Muestra el diálogo del formulario de ingreso
  ///
  /// Parámetros:
  /// - context: Contexto de la pantalla
  /// - ingresoMap: Datos del ingreso a editar (null si es nuevo)
  ///
  /// Características:
  /// - Usa CustomFormDialog para ocupar todo el espacio
  /// - Header con gradiente
  /// - Botón cerrar en la esquina
  /// - Scroll automático para contenido largo
  void _mostrarDialogo(BuildContext context,
      [Map<String, dynamic>? ingresoMap]) {
    // Convertir mapa a objeto Ingreso si viene de edición
    Ingreso? ingreso;
    if (ingresoMap != null) {
      ingreso = Ingreso.fromMap(ingresoMap);
      _editId = ingreso.id;
    } else {
      _editId = null;
    }

    // GlobalKey para validar el formulario
    final formKey = GlobalKey<FormState>();

    // Mostrar el diálogo
    showDialog(
      context: context,
      builder: (dialogContext) => CustomFormDialog(
        // Título del diálogo
        title: _editId == null ? 'Nuevo Ingreso' : 'Editar Ingreso',

        // GlobalKey del formulario
        formKey: formKey,

        // Callback al cancelar
        onCancel: () => Navigator.pop(dialogContext),

        // Callback al guardar
        onSave: () {
          // Validar el formulario
          if (formKey.currentState!.validate()) {
            // El formulario se guarda a través del callback onSave del IngresoFrom
            // No necesitamos hacer nada aquí
          }
        },

        // Contenido del diálogo (el formulario)
        children: [
          IngresoFrom(
            ingreso: ingreso,
            // Callback cuando se guarda el formulario
            onSave: (ing) => _guardarIngreso(ing, parentContext: context),
            // Callback cuando se cancela el formulario
            onCancel: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  /// Muestra el diálogo para seleccionar columnas visibles en la tabla
  ///
  /// Permite al usuario elegir qué columnas mostrar en la tabla de ingresos
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
                  // Opciones de columnas disponibles
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
                        // Actualizar la tabla
                        setState(() {});
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
