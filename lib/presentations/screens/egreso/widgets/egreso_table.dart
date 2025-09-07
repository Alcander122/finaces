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

    // Si hay datos, tomamos las claves del primer egreso como referencia
    if (egresos.isNotEmpty) {
      camposDisponibles = egresos.first.keys.toSet();
    }

    // Remover campos que no se deben mostrar
    camposDisponibles.remove('id');
    camposDisponibles.remove('fecha');
    camposDisponibles.remove('Concepto');

    // Filtrar campos visibles que están disponibles
    List<String> camposMostrar = camposVisibles
        .where((campo) => camposDisponibles.contains(campo))
        .toList();

    if (egresos.isEmpty) {
      return const Center(child: Text('No hay ingresos disponibles'));
    }

    final formatoMoneda = NumberFormat("#,##0", "es_CO");

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          // ✅ Columna de Acciones al inicio
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

          // Luego las demás columnas visibles
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
        ],
        rows: egresos.map((egreso) {
          // ✅ Construimos la lista de celdas en el orden correcto
          List<DataCell> celdas = [];

          // Primero: la celda de acciones
          celdas.add(
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
          );

          // Luego: las celdas de datos
          for (var campo in camposMostrar) {
            final valor = egreso[campo];
            celdas.add(
              DataCell(
                campo == 'fechaPago' && valor is Timestamp
                    ? Text(DateFormat('dd/MM/yyyy').format(valor.toDate()))
                    : campo == 'valor' && valor != null
                        ? Text('\$${formatoMoneda.format(valor)}')
                        : campo == 'quincena'
                            ? Text(_formatearPeriodo(valor))
                            : Text(valor?.toString() ?? ''),
              ),
            );
          }

          return DataRow(cells: celdas);
        }).toList(),
      ),
    );
  }

  // Diálogo de confirmación al eliminar
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

  // Formatea el campo 'quincena'
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
