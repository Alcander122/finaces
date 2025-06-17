import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/presentations/screens/ingresos/widgets/customtable_styles.dart';

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
    Set<String> camposDisponibles = {};
    if (ingresos.isNotEmpty) {
      camposDisponibles = ingresos.first.keys.toSet();
    }
    List<String> camposMostrar = camposVisibles
        .where((campo) => camposDisponibles.contains(campo))
        .toList();

    //Se eliminan dos columnas de la interfaz. PENDIENTE REVISION DE REUSO
    camposMostrar.remove('quincena');
    camposMostrar.remove('concepto');
    if (ingresos.isEmpty) {
      return Center(
        child: Text('No hay ingresos disponibles'),
      );
    }
    final formatoMoneda = NumberFormat("#,##0", "es_CO");
    return SingleChildScrollView(
      child: DataTable(
        columns: [
          for (var campo in camposMostrar)
            DataColumn(
              label: Container(
                decoration: CustomTableStyles.headerDecoration,
                padding: CustomTableStyles.headerPadding,
                child: Center(
                  child: Text(
                    campo == 'fechaIngreso' ? 'Fecha Ingreso' : campo,
                    style: CustomTableStyles.headerTextStyle,
                  ),
                ),
              ),
            ),
          DataColumn(
            label: Container(
              decoration: CustomTableStyles.headerDecoration,
              padding: CustomTableStyles.headerPadding,
              child: Text(
                'Acciones',
                style: CustomTableStyles.headerTextStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
        rows: ingresos.map((ingreso) {
          return DataRow(
            cells: [
              for (var campo in camposMostrar)
                DataCell(
                  campo == 'fechaIngreso' && ingreso[campo] is Timestamp
                      ? Text(DateFormat('dd/MM/yyyy')
                          .format((ingreso[campo] as Timestamp).toDate()))
                      : campo == 'valor' && ingreso[campo] != null
                          ? Text('\$${formatoMoneda.format(ingreso[campo])}')
                          : Text(ingreso[campo]?.toString() ?? ''),
                ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => onEdit(ingreso),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _confirmarEliminar(context, ingreso['id'].toString()),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar ingreso'),
        content: Text('¿Estás seguro de que deseas eliminar este ingreso?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete(id);
            },
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
