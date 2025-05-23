// Importaciones necesarias para la tabla de ingresos
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Clase que representa la tabla de ingresos
class IngresoTable extends StatelessWidget {
  // Parámetros del constructor:
  // - ingresos: Lista de ingresos a mostrar en la tabla
  // - onEdit: Callback para cuando se desea editar un ingreso
  // - onDelete: Callback para cuando se desea eliminar un ingreso
  // - camposVisibles: Lista de campos que deben ser visibles en la tabla
  // - userID: Identificador del usuario actual
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

    // Filtrar los campos visibles basados en la lista proporcionada
    List<String> camposMostrar = camposVisibles
        .where((campo) => camposDisponibles.contains(campo))
        .toList();

    // Mostrar un mensaje si no hay ingresos
    if (ingresos.isEmpty) {
      return Center(
        child: Text('No hay ingresos disponibles'),
      );
    }

    return SingleChildScrollView(
      child: DataTable(
        columns: [
          // Generar columnas solo para los campos visibles
          for (var campo in camposMostrar)
            DataColumn(
              label: Text(campo == 'anio' ? 'año' : campo), // Mostrar 'año' en lugar de 'anio'
            ),
          // Columna para las acciones (editar y eliminar)
          const DataColumn(label: Text('Acciones')),
        ],
        rows: ingresos.map((ingreso) {
          return DataRow(
            cells: [
              // Generar celdas solo para los campos visibles
              for (var campo in camposMostrar)
                DataCell(
                  // Formatear la fecha si es un Timestamp
                  campo == 'fecha' && ingreso[campo] is Timestamp
                      ? Text(DateFormat('dd/MM/yyyy')
                          .format((ingreso[campo] as Timestamp).toDate()))
                      : Text(ingreso[campo]?.toString() ?? ''),
                ),
              // Celda para los botones de acción
              DataCell(
                Row(
                  children: [
                    // Botón para editar el ingreso
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => onEdit(ingreso),
                    ),
                    // Botón para eliminar el ingreso
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

  // Método para confirmar la eliminación de un ingreso
  void _confirmarEliminar(BuildContext context, String id) {
    // Mostrar un diálogo de confirmación
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar ingreso'),
        content: Text('¿Estás seguro de que deseas eliminar este ingreso?'),
        actions: [
          // Botón para cancelar la eliminación
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          // Botón para confirmar la eliminación
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