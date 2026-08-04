import 'package:finances/core/data/providers/Ingreso_provider.dart';
import 'package:finances/presentations/screens/ingresos/Ingreso_form.dart';
import 'package:finances/presentations/screens/ingresos/widgets/ingreso_table.dart';
import 'package:finances/presentations/screens/ingresos/widgets/ingresos_skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:finances/presentations/screens/ingresos/widgets/Ingreso_chart.dart';
import 'package:finances/presentations/widgets/column_selection_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/theme/themes.dart';

class IngresosScreen extends ConsumerStatefulWidget {
  const IngresosScreen({super.key});

  @override
  IngresosScreenState createState() => IngresosScreenState();
}

class IngresosScreenState extends ConsumerState<IngresosScreen> {
  final List<String> _allColumns = [
    'Periodo',
    'Fecha Ingreso',
    'Categoría',
    'Concepto',
    'Valor',
  ];

  Set<String> _visibleColumns = {
    'Periodo',
    'Fecha Ingreso',
    'Categoría',
    'Valor',
  };

  final Map<String, String> _columnMapping = {
    'Periodo': 'quincena',
    'Fecha Ingreso': 'fechaIngreso',
    'Categoría': 'categoria',
    'Concepto': 'concepto',
    'Valor': 'valor',
  };

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

  List<Map<String, dynamic>> _convertIngresosToMap(List<Ingreso> ingresos) {
    return ingresos.map((ingreso) {
      return {
        'id': ingreso.id,
        'quincena': ingreso.quincena,
        'fechaIngreso': ingreso.fechaIngreso,
        'categoria': ingreso.categoria,
        'concepto': ingreso.concepto,
        'valor': ingreso.valor,
      };
    }).toList();
  }

  void _deleteIngreso(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await ref.read(ingresosServiceProvider).eliminarIngreso(user.uid, id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
    }
  }

  Future<void> _refreshData() async {
    // ignore: unused_result
    ref.refresh(ingresosProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final ingresosAsync = ref.watch(ingresosProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBgColor,
      appBar: AppBarFinances(
        title: 'Ingresos',
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
            builder: (context) => const IngresoForm(ingreso: null),
          ),
        ),
        backgroundColor: Themes.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ingreso', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
      body: ingresosAsync.when(
        loading: () => const IngresosSkeletonLoader(),
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
        data: (ingresos) {
          debugPrint('✅ ingresos_screen: Se recibieron ${ingresos.length} ingresos');

          final ingresosMap = _convertIngresosToMap(ingresos);

          return RefreshIndicator(
            onRefresh: _refreshData,
            color: Themes.green,
            backgroundColor: context.scaffoldBgColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 80.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    IncomeChart(ingresos: ingresos),
                    const SizedBox(height: 24),

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

                    if (ingresos.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.account_balance_wallet, size: 64, color: context.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                              const SizedBox(height: 16),
                              Text(
                                'No hay ingresos registrados aún.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.isDarkMode ? Colors.grey[300] : Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      IngresoTable(
                        ingresos: ingresosMap,
                        onEdit: (ingresoMap) {
                          final fechaIngreso = ingresoMap['fechaIngreso'] is DateTime
                              ? ingresoMap['fechaIngreso'] as DateTime
                              : DateTime.now();

                          final fecha = ingresoMap['fecha'] is DateTime
                              ? ingresoMap['fecha'] as DateTime
                              : DateTime.now();

                          final ingreso = Ingreso(
                            id: ingresoMap['id']?.toString() ?? '',
                            quincena: ingresoMap['quincena']?.toString() ?? '',
                            fechaIngreso: fechaIngreso,
                            fecha: fecha,
                            categoria: ingresoMap['categoria']?.toString() ?? '',
                            concepto: ingresoMap['concepto']?.toString() ?? '',
                            valor: ingresoMap['valor'] is int
                                ? ingresoMap['valor'] as int
                                : int.tryParse(
                                        ingresoMap['valor']?.toString() ?? '0') ??
                                    0,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IngresoForm(ingreso: ingreso),
                            ),
                          );
                        },
                        onDelete: _deleteIngreso,
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
