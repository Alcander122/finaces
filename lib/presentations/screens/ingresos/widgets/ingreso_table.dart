// ingreso_table.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/screens/ingresos/widgets/customtable_styles.dart';

class IngresoTable extends StatelessWidget {
  final List<Map<String, dynamic>> ingresos;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(String) onDelete;
  final List<String> camposVisibles;
  final String userID;
  final int currentPage;
  final int itemsPerPage;

  const IngresoTable({
    super.key,
    required this.ingresos,
    required this.onEdit,
    required this.onDelete,
    required this.camposVisibles,
    required this.userID,
    this.currentPage = 1,
    this.itemsPerPage = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (ingresos.isEmpty) {
      return const Center(
        child: Text('No hay ingresos disponibles'),
      );
    }

    // 🔹 Calcular rango de datos para la página actual
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    final paginatedIngresos = ingresos.sublist(
      startIndex,
      endIndex > ingresos.length ? ingresos.length : endIndex,
    );

    // 🔹 Calcular totales
    ingresos.fold<double>(
      0,
      // ignore: avoid_types_as_parameter_names
      (sum, ingreso) => sum + (ingreso['valor']?.toDouble() ?? 0),
    );
    // ignore: unused_local_variable
    final totalPagina = paginatedIngresos.fold<double>(
      0,
      // ignore: avoid_types_as_parameter_names
      (sum, ingreso) => sum + (ingreso['valor']?.toDouble() ?? 0),
    );

    // 🔹 Obtener campos disponibles
    final Set<String> camposDisponibles = ingresos.first.keys.toSet();
    final List<String> camposMostrar = camposVisibles
        .where((campo) => camposDisponibles.contains(campo))
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: Container(
              decoration: CustomTableStyles.headerDecoration,
              padding: CustomTableStyles.headerPadding,
              child: Center(
                child: Text(
                  'Acciones',
                  style: CustomTableStyles.headerTextStyle,
                ),
              ),
            ),
          ),
          for (var campo in camposMostrar)
            DataColumn(
              label: Container(
                decoration: CustomTableStyles.headerDecoration,
                padding: CustomTableStyles.headerPadding,
                child: Center(
                  child: Text(
                    _formatearNombreCampo(campo),
                    style: CustomTableStyles.headerTextStyle,
                  ),
                ),
              ),
            ),
        ],
        rows: [
          // 🔹 Filas de ingresos normales
          ...paginatedIngresos.map((ingreso) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Tooltip(
                          message: "Actualizar registro",
                          child: IconButton(
                            icon: const Icon(Icons.edit,
                                color: Themes.primary, size: 18),
                            onPressed: () => onEdit(ingreso),
                          ),
                        ),
                        Tooltip(
                          message: "Eliminar registro",
                          child: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red, size: 18),
                            onPressed: () => _confirmarEliminar(
                                context, ingreso['id'].toString()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                for (var campo in camposMostrar)
                  DataCell(
                    _formatearCelda(campo, ingreso[campo]),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ingreso'),
        content:
            const Text('¿Estás seguro de que deseas eliminar este ingreso?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete(id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _formatearCelda(String campo, dynamic valor) {
    if (campo == 'fechaIngreso' && valor is Timestamp) {
      return Text(DateFormat('dd/MM/yyyy').format(valor.toDate()));
    } else if (campo == 'valor' && valor != null) {
      return Text(UIHelpers.formatCurrency(valor.toDouble()));
    } else if (campo == 'quincena') {
      return Text(_formatearPeriodo(valor));
    } else {
      return Text(valor?.toString() ?? '');
    }
  }

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

  String _formatearNombreCampo(String campo) {
    switch (campo) {
      case 'fechaIngreso':
        return 'Fecha Ingreso';
      case 'quincena':
        return 'Periodo';
      case 'valor':
        return 'Valor';
      default:
        return campo[0].toUpperCase() + campo.substring(1);
    }
  }
}
