import 'package:finances/presentations/screens/egreso/egreso_form.dart';
import 'package:flutter/material.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'package:intl/intl.dart';

import '../../../../core/data/utils/ui_helpers.dart';

class EgresoDataSource extends DataTableSource {
  final List<Egreso> egresos;
  final Set<String> visibleColumns;
  final void Function(Egreso) onDelete;
  final BuildContext context;

  EgresoDataSource(
    this.egresos,
    this.visibleColumns,
    this.onDelete,
    this.context,
  );

  @override
  int get rowCount => egresos.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;

  @override
  DataRow getRow(int index) {
    if (index >= egresos.length) {
      return DataRow(cells: [DataCell(const Text('...'))]);
    }

    final egreso = egresos[index];

    // ✅ Aseguramos que el número de celdas coincida con el número de columnas
    final List<DataCell> cells = [];

    // Columna de acciones
    cells.add(
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EgresoForm(egreso: egreso),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () => onDelete(egreso),
            ),
          ],
        ),
      ),
    );

    // Columnas visibles (debes tener exactamente 4 columnas visibles para que sumen 5 con "Acciones")
    final List<String> columnasVisiblesOrdenadas = [
      'Periodo',
      'Fecha Pago',
      'Valor',
      'Estado',
    ];

    for (final column in columnasVisiblesOrdenadas) {
      if (visibleColumns.contains(column)) {
        cells.add(
          DataCell(
            Text(_getCellValue(egreso, column)),
          ),
        );
      }
    }

    // ✅ Verificación de seguridad
    if (cells.length != 5) {
      debugPrint(
          '⚠️ Fila $index tiene ${cells.length} celdas, pero debería tener 5');
      // Añadimos celdas vacías si es necesario
      while (cells.length < 5) {
        cells.add(DataCell(const Text('')));
      }
    }

    return DataRow(
      cells: cells,
    );
  }

  String _getCellValue(Egreso egreso, String column) {
    switch (column) {
      case 'Periodo':
        return _formatearPeriodo(egreso.quincena);
      case 'Fecha Pago':
        return DateFormat('dd/MM/yyyy').format(egreso.fechaPago);
      case 'Valor':
        return UIHelpers.formatCurrency(egreso.valor.toDouble());
      case 'Estado':
        return egreso.estado;
      default:
        return '';
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
}
