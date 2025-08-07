import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/presentations/screens/ingresos/widgets/customtable_styles.dart';

/// Widget para mostrar una tabla de ingresos con campos dinámicos
/// y una columna de acciones al principio.
class IngresoTable extends StatelessWidget {
  final List<Map<String, dynamic>> ingresos;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(String) onDelete;
  final List<String> camposVisibles;
  final String userID;

  const IngresoTable({
    super.key,
    required this.ingresos,
    required this.onEdit,
    required this.onDelete,
    required this.camposVisibles,
    required this.userID,
  });

  @override
  Widget build(BuildContext context) {
    // Mostrar mensaje si no hay ingresos
    if (ingresos.isEmpty) {
      return const Center(
        child: Text('No hay ingresos disponibles'),
      );
    }

    // Obtener campos disponibles del primer ingreso
    final Set<String> camposDisponibles = ingresos.first.keys.toSet();

    // Filtrar campos visibles
    final List<String> camposMostrar = camposVisibles
        .where((campo) => camposDisponibles.contains(campo))
        .toList();

    // Formateador de moneda para Colombia
    final formatoMoneda = NumberFormat("#,##0", "es_CO");

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          // Columna de acciones (primera columna)
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
          // Columnas dinámicas basadas en los campos visibles
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
        rows: ingresos.map((ingreso) {
          return DataRow(
            cells: [
              // Celda de acciones (debe ir de primera)
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
                              color: Colors.blue, size: 18),
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

              // Celdas dinámicas con datos
              for (var campo in camposMostrar)
                DataCell(
                  _formatearCelda(campo, ingreso[campo], formatoMoneda),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Diálogo de confirmación para eliminar ingreso
  void _confirmarEliminar(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ingreso'),
        content: const Text('¿Estás seguro de que deseas eliminar este ingreso?'),
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

  /// Devuelve un widget con el texto formateado para cada celda
  Widget _formatearCelda(
      String campo, dynamic valor, NumberFormat formatoMoneda) {
    if (campo == 'fechaIngreso' && valor is Timestamp) {
      return Text(DateFormat('dd/MM/yyyy').format(valor.toDate()));
    } else if (campo == 'valor' && valor != null) {
      return Text('\$${formatoMoneda.format(valor)}');
    } else if (campo == 'quincena') {
      return Text(_formatearPeriodo(valor));
    } else {
      return Text(valor?.toString() ?? '');
    }
  }

  /// Convierte el valor de quincena a texto legible
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

  /// Formatea el nombre del campo para mostrarlo como encabezado
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
