import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    if (ingresos.isEmpty) {
      return Center(
        child: Text('No hay ingresos disponibles'),
      );
    }

    return SingleChildScrollView(
      child: DataTable(
        columns: [
          ...camposMostrar.map(
            (campo) => DataColumn(label: Text(campo)),
          ),
          const DataColumn(label: Text('Acciones')),
        ],
        rows: ingresos.map((ingreso) {
          return DataRow(
            cells: [
              ...camposMostrar.map(
                (campo) {
                  if (campo == 'fecha' && ingreso[campo] is Timestamp) {
                    return DataCell(
                      Text(DateFormat('dd/MM/yyyy')
                          .format((ingreso[campo] as Timestamp).toDate())),
                    );
                  }
                  return DataCell(
                    Text(ingreso[campo]?.toString() ?? ''),
                  );
                },
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
