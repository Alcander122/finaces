import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/presentations/screens/egreso/egreso_form.dart';
import 'package:finances/presentations/screens/egreso/widgets/egreso_table.dart';
import 'package:finances/presentations/screens/egreso/widgets/egresos_skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:finances/presentations/screens/Egreso/widgets/egreso_chart.dart';
import 'package:finances/presentations/widgets/column_selection_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/theme/themes.dart';

class EgresosScreen extends ConsumerStatefulWidget {
  const EgresosScreen({super.key});

  @override
  EgresosScreenState createState() => EgresosScreenState();
}

class EgresosScreenState extends ConsumerState<EgresosScreen> {
  /// Lista de todas las columnas posibles (nombres bonitos para el usuario)
  final List<String> _allColumns = [
    'Periodo',
    'Fecha Pago',
    'Categoría',
    'Concepto',
    'Valor',
    'Descripción',
    'Estado',
  ];

  /// Columnas visibles por defecto
  Set<String> _visibleColumns = {
    'Periodo',
    'Fecha Pago',
    'Valor',
    'Estado',
  };

  /// Mapeo entre nombre visible <-> nombre real en el modelo
  final Map<String, String> _columnMapping = {
    'Periodo': 'quincena',
    'Fecha Pago': 'fechaPago',
    'Categoría': 'categoria',
    'Concepto': 'concepto',
    'Valor': 'valor',
    'Descripción': 'descripcion',
    'Estado': 'estado',
  };

  /// Muestra el diálogo para seleccionar columnas
  void _showColumnSelectionDialog() async {
    final selectedColumns = await showDialog<Set<String>>(
      context: context,
      builder: (context) => ColumnSelectionDialog(
        selectedColumns: _visibleColumns,
        allColumns: _allColumns,
      ),
    );

    if (selectedColumns != null) {
      setState(() {
        _visibleColumns = selectedColumns;
      });
    }
  }

  /// Convierte una lista de Egreso a Map para usar con EgresoTable
  List<Map<String, dynamic>> _convertEgresosToMap(List<Egreso> egresos) {
    return egresos.map((egreso) {
      return {
        'id': egreso.id,
        'quincena': egreso.quincena,
        'fechaPago': egreso.fechaPago,
        'categoria': egreso.categoria,
        'concepto': egreso.concepto,
        'valor': egreso.valor,
        'descripcion': egreso.descripcion,
        'estado': egreso.estado,
      };
    }).toList();
  }

  /// Elimina un egreso
  void _deleteEgreso(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await ref.read(egresoServiceProvider).eliminarEgreso(user.uid, id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
    }
  }

  Future<void> _refreshData() async {
    // ignore: unused_result
    ref.refresh(egresosProvider);
    await Future.delayed(const Duration(milliseconds: 500)); // Simula tiempo de red
  }

  @override
  Widget build(BuildContext context) {
    final egresosAsync = ref.watch(egresosProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBgColor,
      appBar: AppBarFinances(
        title: 'Gastos',
        showProfileIcon: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            color: Colors.white,
            onPressed: _showColumnSelectionDialog,
            tooltip: 'Filtros y columnas',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EgresoForm(egreso: null),
          ),
        ),
        backgroundColor: Themes.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Gasto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
      body: egresosAsync.when(
        loading: () => const EgresosSkeletonLoader(),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Themes.red, size: 64),
              const SizedBox(height: 16),
              Text('Error: $error', style: TextStyle(color: context.isDarkMode ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Reintentar'),
              )
            ],
          )
        ),
        data: (egresos) {
          debugPrint('✅ egresos_screen: Se recibieron ${egresos.length} egresos');

          // Convertimos los egresos a formato Map
          final egresosMap = _convertEgresosToMap(egresos);

          return RefreshIndicator(
            onRefresh: _refreshData,
            color: context.colors.primary,
            backgroundColor: context.scaffoldBgColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 80.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashboard Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      child: Text(
                        'Resumen Financiero',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.titleColor,
                        ),
                      ),
                    ),
                    // Gráfico
                    EgresoChart(egresos: egresos),
                    const SizedBox(height: 24),

                    // Título de sección de tabla
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      child: Text(
                        'Movimientos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.titleColor,
                        ),
                      ),
                    ),

                    // Mensaje si no hay datos
                    if (egresos.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long, size: 64, color: Colors.grey[600]),
                              const SizedBox(height: 16),
                              Text(
                                'No hay gastos registrados aún.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // ✅ Usamos el componente EgresoTable
                      EgresoTable(
                        egresos: egresosMap,
                        onEdit: (egresoMap) {
                          final fechaPago = egresoMap['fechaPago'] is DateTime
                              ? egresoMap['fechaPago'] as DateTime
                              : DateTime.now();

                          final fecha = egresoMap['fecha'] is DateTime
                              ? egresoMap['fecha'] as DateTime
                              : DateTime.now();

                          final egreso = Egreso(
                            id: egresoMap['id']?.toString() ?? '',
                            quincena: egresoMap['quincena']?.toString() ?? '',
                            fechaPago: fechaPago,
                            fecha: fecha,
                            categoria: egresoMap['categoria']?.toString() ?? '',
                            concepto: egresoMap['concepto']?.toString() ?? '',
                            valor: egresoMap['valor'] is int
                                ? egresoMap['valor'] as int
                                : int.tryParse(
                                        egresoMap['valor']?.toString() ?? '0') ??
                                    0,
                            descripcion:
                                egresoMap['descripcion']?.toString() ?? '',
                            estado: egresoMap['estado']?.toString() ?? '',
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EgresoForm(egreso: egreso),
                            ),
                          );
                        },
                        onDelete: _deleteEgreso,
                        // 🔑 Pasamos las claves reales usando el mapping
                        camposVisibles: _visibleColumns
                            .map((col) => _columnMapping[col]!)
                            .toList(),
                        userID: FirebaseAuth.instance.currentUser?.uid ?? '',
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
