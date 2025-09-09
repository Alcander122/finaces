import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/presentations/screens/egreso/egreso_form.dart';
import 'package:finances/presentations/screens/egreso/widgets/egreso_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:finances/presentations/screens/Egreso/widgets/egreso_chart.dart';
import 'package:finances/presentations/widgets/column_selection_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finances/presentations/theme/themes.dart';

class EgresosScreen extends ConsumerStatefulWidget {
  const EgresosScreen({super.key});

  @override
  EgresosScreenState createState() => EgresosScreenState();
}

class EgresosScreenState extends ConsumerState<EgresosScreen> {
  /// Lista de todas las columnas posibles
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

  /// Muestra el diálogo para seleccionar columnas [[5]]
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

  @override
  Widget build(BuildContext context) {
    final egresosAsync = ref.watch(egresosProvider);

    return Scaffold(
      backgroundColor: Themes.light,
      appBar: AppBarFinances(
        title: 'Egresos',
        showProfileIcon: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            color: Colors.white,
            onPressed: _showColumnSelectionDialog,
            tooltip: 'Editar columnas visibles',
          ),
        ],
      ),
      body: egresosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (egresos) {
          debugPrint(
              '✅ egresos_screen: Se recibieron ${egresos.length} egresos');

          // Convertimos los egresos a formato Map para usar con EgresoTable
          final egresosMap = _convertEgresosToMap(egresos);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gráfico
                  EgresoChart(egresos: egresos),
                  const SizedBox(height: 16),

                  // Mensaje si no hay datos
                  if (egresos.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No hay egresos registrados aún.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  else
                    // ✅ Usamos el componente EgresoTable corregido
                    // que incluye paginación y scroll horizontal [[3]]
                    EgresoTable(
                      egresos: egresosMap,
                      onEdit: (egresoMap) {
                        // ✅ Conversión segura con manejo de valores nulos
                        // Extraemos y convertimos las fechas con valores por defecto si son nulas
                        final fechaPago = egresoMap['fechaPago'] is DateTime
                            ? egresoMap['fechaPago'] as DateTime
                            : DateTime.now();

                        final fecha = egresoMap['fecha'] is DateTime
                            ? egresoMap['fecha'] as DateTime
                            : DateTime.now();

                        // ✅ Conversión segura de todos los campos con valores por defecto
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
                      camposVisibles: _visibleColumns.toList(),
                      userID: FirebaseAuth.instance.currentUser?.uid ?? '',
                    ),

                  const SizedBox(height: 24),

                  // Botón nuevo egreso
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
                          builder: (context) => EgresoForm(egreso: null),
                        ),
                      ),
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
          );
        },
      ),
    );
  }
}
