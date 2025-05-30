import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EgresoTable extends StatelessWidget {
  final List<Map<String, dynamic>> egresos;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(String) onDelete;
  final List<String> camposVisibles;

  const EgresoTable({
    super.key,
    required this.egresos,
    required this.onEdit,
    required this.onDelete,
    required this.camposVisibles,
  });

  @override
  Widget build(BuildContext context) {
    if (egresos.isEmpty) {
      return const Center(child: Text('No hay egresos disponibles'));
    }

    final camposDisponibles = egresos.first.keys.toSet();
    final camposMostrar = camposVisibles
        .where((campo) => camposDisponibles.contains(campo))
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          for (var campo in camposMostrar)
            DataColumn(
              label: Text(
                campo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          const DataColumn(label: Text('Acciones')),
        ],
        rows: egresos.map((egreso) {
          return DataRow(
            cells: [
              for (var campo in camposMostrar)
                DataCell(
                  Text(_formatCell(egreso[campo], campo)),
                ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => onEdit(egreso),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => onDelete(egreso['id'].toString()),
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

  String _formatCell(dynamic value, String campo) {
    if (campo == 'fecha' && value is DateTime) {
      return DateFormat('dd/MM/yyyy').format(value);
    } else if (campo == 'valor' && value is num) {
      return NumberFormat.currency(
              locale: 'es_CO', symbol: '\$', decimalDigits: 0)
          .format(value);
    }
    return value?.toString() ?? '';
  }
}
