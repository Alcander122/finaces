import 'package:finances/presentations/widgets/customtable_styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IngresoTable extends StatelessWidget {
  final List<Map<String, dynamic>> egresos;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(String) onDelete;
  final List<String> camposVisibles;
  final String userID;

  const IngresoTable({
    super.key,
    required this.egresos,
    required this.onEdit,
    required this.onDelete,
    required this.camposVisibles,
    required this.userID,
  });

  @override
  Widget build(BuildContext context) {
    Set<String> camposDisponibles = {};

    // Si hay datos, se toman las claves del primer elemento como campos disponibles
    if (egresos.isNotEmpty) {
      camposDisponibles = egresos.first.keys.toSet();
    }

    // Removemos campos que no se deben mostrar en la tabla
    camposDisponibles.remove('id');
    camposDisponibles.remove('fecha');

    // Se genera la lista de campos a mostrar en la tabla a partir de los visibles y disponibles
    List<String> camposMostrar = camposVisibles
        .where((campo) => camposDisponibles.contains(campo))
        .toList();

    // ✅ Aseguramos que 'Concepto' no se muestre aunque esté en camposVisibles
    camposDisponibles.remove('Concepto');

    if (egresos.isEmpty) {
      return const Center(child: Text('No hay ingresos disponibles'));
    }

    final formatoMoneda = NumberFormat("#,##0", "es_CO");

    return SingleChildScrollView(
      child: DataTable(
        columns: [
          // Construimos las columnas basadas en los campos a mostrar
          for (var campo in camposMostrar)
            DataColumn(
              label: Container(
                decoration: CustomTableStyles.headerDecoration,
                padding: CustomTableStyles.headerPadding,
                child: Center(
                  child: Text(
                    campo == 'fechaPago' ? 'Fecha de Pago' : campo,
                    style: CustomTableStyles.headerTextStyle,
                  ),
                ),
              ),
            ),
          // Columna para acciones (editar/eliminar)
          DataColumn(
            label: Container(
              decoration: CustomTableStyles.headerDecoration,
              padding: CustomTableStyles.headerPadding,
              child: const Text(
                'Acciones',
                style: CustomTableStyles.headerTextStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
        rows: egresos.map((egreso) {
          return DataRow(
            cells: [
              // Llenamos las celdas por cada campo visible
              for (var campo in camposMostrar)
                DataCell(
                  campo == 'fechaPago' && egreso[campo] is Timestamp
                      ? Text(DateFormat('dd/MM/yyyy')
                          .format((egreso[campo] as Timestamp).toDate()))
                      : campo == 'valor' && egreso[campo] != null
                          ? Text('\$${formatoMoneda.format(egreso[campo])}')
                          : campo == 'quincena'
                              ? Text(_formatearPeriodo(egreso[campo]))
                              : Text(egreso[campo]?.toString() ?? ''),
                ),

              // Celda de acciones
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => onEdit(egreso),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _confirmarEliminar(context, egreso['id'].toString()),
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

  // Diálogo para confirmar eliminación
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
