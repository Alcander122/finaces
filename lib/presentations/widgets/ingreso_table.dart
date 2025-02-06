import 'package:flutter/material.dart';
import 'package:finances/core/data/services/ingresos_service.dart';
import 'package:finances/core/data/models/user_model.dart';

class User {
  final String uid;
  User({required this.uid});
}

class IngresoTable extends StatelessWidget {
  final List<Map<String, dynamic>> ingresos;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(String) onDelete;
  final List<String> camposVisibles;
  final String userID; // Se asegura consistencia con el uso de userID

  final _ingresosService = IngresosService();

  IngresoTable({
    required this.ingresos,
    required this.onEdit,
    required this.onDelete,
    required this.camposVisibles,
    required this.userID,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _ingresosService.obtenerIngresos(userID), // Uso de userID aquí
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error al cargar ingresos');
        } else if (snapshot.hasData) {
          return DataTable(
            columns: camposVisibles
                .map((campo) => DataColumn(label: Text(campo)))
                .toList(),
            rows: snapshot.data!.map((ingreso) {
              return DataRow(
                cells: camposVisibles.map((campo) {
                  return DataCell(Text(ingreso[campo]?.toString() ?? ''));
                }).toList(),
              );
            }).toList(),
          );
        } else {
          return Text('No hay ingresos disponibles');
        }
      },
    );
  }
}
