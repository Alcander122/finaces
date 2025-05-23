import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/presentations/screens/Egreso/egreso_form.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/presentations/screens/Egreso/widgets/egreso_chart.dart';
import 'package:finances/presentations/widgets/column_selection_dialog.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EgresosScreen extends ConsumerStatefulWidget {
  const EgresosScreen({super.key});

  @override
  EgresosScreenState createState() => EgresosScreenState();
}

class EgresosScreenState extends ConsumerState<EgresosScreen> {
  final _allColumns = [
    'Quincena',
    'Fecha',
    'Mes',
    'Día',
    'Año',
    'Categoría',
    'Concepto',
    'Valor',
    'Descripción',
    'Estado',
  ];

  Set<String> _visibleColumns = {
    'Quincena',
    'Fecha',
    'Concepto',
    'Valor',
    'Estado',
  };

  String _getEgresoCellValue(Egreso egreso, String column) {
    switch (column) {
      case 'Quincena':
        return egreso.quincena;
      case 'Fecha':
        return DateFormat('dd/MM/yyyy').format(egreso.fecha);
      case 'Mes':
        return egreso.mes;
      case 'Día':
        return egreso.dia.toString();
      case 'Año':
        return egreso.anio.toString();
      case 'Categoría':
        return egreso.categoria;
      case 'Concepto':
        return egreso.concepto;
      case 'Valor':
        return '${egreso.valor}';
      case 'Descripción':
        return egreso.descripcion;
      case 'Estado':
        return egreso.estado;
      default:
        return '';
    }
  }

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

  void _deleteEgreso(Egreso egreso) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await ref.read(egresoServiceProvider).eliminarEgreso(user.uid, egreso.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final egresosAsync = ref.watch(egresosProvider);

    return Scaffold(
      appBar: AppBarFinances(
        title: 'Egresos',
        showProfileIcon: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.view_column),
            color: Colors.white,
            onPressed: () => _showColumnSelectionDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EgresoForm()),
        ),
      ),
      body: egresosAsync.when(
        data: (egresos) => SingleChildScrollView(
          child: Column(
            children: [
              // Gráfico de Dona para mostrar la distribución de egresos por categoría
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: EgresoChart(
                  egresos: egresos,
                ),
              ),
              // Tabla de egresos
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    ..._allColumns.where(_visibleColumns.contains).map(
                          (column) => DataColumn(label: Text(column)),
                        ),
                    const DataColumn(label: Text('Acciones')),
                  ],
                  rows: egresos.map((egreso) {
                    return DataRow(
                      cells: [
                        ..._allColumns
                            .where(_visibleColumns.contains)
                            .map((column) {
                          return DataCell(
                            Text(_getEgresoCellValue(egreso, column)),
                          );
                        }),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EgresoForm(egreso: egreso),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () => _deleteEgreso(egreso),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
