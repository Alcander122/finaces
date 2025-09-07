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
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/widgets/reusable_cardtable.dart';

class EgresosScreen extends ConsumerStatefulWidget {
  const EgresosScreen({super.key});

  @override
  EgresosScreenState createState() => EgresosScreenState();
}

class EgresosScreenState extends ConsumerState<EgresosScreen> {
  /// Todas las columnas posibles que puede mostrar la tabla
  final _allColumns = [
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

  /// Retorna el valor adecuado para cada celda en función de la columna
  String _getEgresoCellValue(Egreso egreso, String column) {
    switch (column) {
      case 'Periodo':
        return _formatearPeriodo(egreso.quincena);
      case 'Fecha':
        return DateFormat('dd/MM/yyyy').format(egreso.fecha);
      case 'Fecha Pago':
        return DateFormat('dd/MM/yyyy').format(egreso.fechaPago);
      case 'Categoría':
        return egreso.categoria;
      case 'Concepto':
        return egreso.concepto;
      case 'Valor':
        final formatter = NumberFormat('#,##0', 'es_CO');
        return '\$${formatter.format(egreso.valor)}';
      case 'Descripción':
        return egreso.descripcion;
      case 'Estado':
        return egreso.estado;
      default:
        return '';
    }
  }

  /// Muestra el diálogo para seleccionar las columnas visibles
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

  /// Elimina un egreso del backend usando el proveedor
  void _deleteEgreso(Egreso egreso) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await ref.read(egresoServiceProvider).eliminarEgreso(user.uid, egreso.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observa el estado de los egresos
    final egresosAsync = ref.watch(egresosProvider);

    return Scaffold(
      backgroundColor: Themes.light,
      appBar: AppBarFinances(
        title: 'Egresos',
        showProfileIcon: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.view_column),
            color: Colors.white,
            onPressed: _showColumnSelectionDialog,
          ),
        ],
      ),
      body: egresosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (egresos) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gráfico de donut de egresos por categoría
                EgresoChart(egresos: egresos),
                const SizedBox(height: 16),

                // Tarjeta contenedora de la tabla
                ReusableCardTable(
                  topColorStart: Themes.degradientDark,
                  topColorEnd: Themes.degradientLight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      // ✅ Columnas con acciones al principio
                      columns: [
                        const DataColumn(
                          label: Text(
                            'Acciones',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Columnas seleccionadas por el usuario
                        ..._allColumns.where(_visibleColumns.contains).map(
                              (column) => DataColumn(
                                label: Text(
                                  column,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                      ],

                      // ✅ Filas de datos con acciones primero
                      rows: egresos.map((egreso) {
                        return DataRow(
                          cells: [
                            // ✅ Primera celda: acciones
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        size: 20, color: Colors.blue),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EgresoForm(egreso: egreso),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        size: 20, color: Colors.red),
                                    onPressed: () => _deleteEgreso(egreso),
                                  ),
                                ],
                              ),
                            ),

                            // ✅ Celdas de datos en orden de columnas visibles
                            ..._allColumns.where(_visibleColumns.contains).map(
                                  (column) => DataCell(
                                    Text(_getEgresoCellValue(egreso, column)),
                                  ),
                                ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Botón para agregar un nuevo egreso
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Nuevo Egreso',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EgresoForm(),
                      ),
                    ),
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
      ),
    );
  }

  /// Traduce los valores de la columna 'Periodo' a texto más descriptivo
  String _formatearPeriodo(dynamic valor) {
    switch (valor) {
      case 'Primera':
        return 'Primera Quincena';
      case 'Segunda':
        return 'Segunda Quincena';
      case 'Diario':
        return 'Diario';
      case 'Mensual':
        return 'Mensual';
      default:
        return valor?.toString() ?? '';
    }
  }
}
