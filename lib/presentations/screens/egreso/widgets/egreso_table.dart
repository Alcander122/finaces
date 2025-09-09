import 'dart:math';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/presentations/theme/themes.dart';

/// 📊 Tabla dinámica de egresos con diseño profesional y manejo de desbordamiento
/// - Soluciona el problema de desbordamiento horizontal
/// - Mantiene el diseño con gradiente azul oscuro
/// - Alineación de datos a la derecha
/// - Bordes finos entre filas
/// - Fondo alternado blanco/gris claro
/// - Iconos de acción con colores específicos
class EgresoTable extends StatefulWidget {
  final List<Map<String, dynamic>> egresos; // lista de egresos como Map
  final void Function(Map<String, dynamic>) onEdit; // acción al editar
  final void Function(String) onDelete; // acción al eliminar
  final List<String> camposVisibles; // columnas a mostrar
  final String userID; // id del usuario autenticado

  const EgresoTable({
    super.key,
    required this.egresos,
    required this.onEdit,
    required this.onDelete,
    required this.camposVisibles,
    required this.userID,
  });

  @override
  EgresoTableState createState() => EgresoTableState();
}

class EgresoTableState extends State<EgresoTable> {
  int _rowsPerPage = 5; // número de filas por página
  int _currentPage = 0; // página actual
  final List<int> _rowsPerPageOptions = [5, 10, 20, 50]; // opciones de paginado

  /// ✅ Si cambia la cantidad de egresos, reiniciamos a la primera página
  @override
  void didUpdateWidget(covariant EgresoTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.egresos.length != oldWidget.egresos.length) {
      setState(() {
        _currentPage = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚨 Si no hay egresos, mostramos un mensaje
    if (widget.egresos.isEmpty) {
      return const Center(child: Text('No hay egresos disponibles'));
    }

    // Normalizamos los campos visibles
    final camposMostrar = widget.camposVisibles;

    // 📌 Paginación: calculamos los items de la página actual
    final total = widget.egresos.length;
    final totalPages = max(1, (total / _rowsPerPage).ceil());

    // aseguramos que la página no se pase del límite
    final safePage = _currentPage >= totalPages ? 0 : _currentPage;

    final start = safePage * _rowsPerPage;
    final end = min(start + _rowsPerPage, total);
    final pageItems = widget.egresos.sublist(start, end);

    // 🚨 Si por alguna razón la página está vacía
    if (pageItems.isEmpty) {
      return const Center(
          child: Text("No hay egresos para mostrar en esta página"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ✅ Envolver la tabla en un Card para bordes redondeados y sombra
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              // ✅ Solución principal: Usar LayoutBuilder para calcular el ancho máximo disponible
              LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth, // Forzamos el ancho máximo
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                          maxWidth: double.infinity,
                        ),
                        child: _buildDataTable(camposMostrar, pageItems),
                      ),
                    ),
                  );
                },
              ),

              // ✅ Línea divisoria sutil debajo de la tabla
              Container(
                height: 1,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 📌 Paginador: info + controles de navegación RESPONSIVO
        _buildResponsivePagination(total, totalPages, safePage, start, end),
      ],
    );
  }

  /// Construye el DataTable con el diseño profesional
  Widget _buildDataTable(
    List<String> camposMostrar,
    List<Map<String, dynamic>> pageItems,
  ) {
    return DataTable(
      // ✅ Encabezado con gradiente azul oscuro
      headingRowColor: WidgetStateProperty.all(Themes.degradientDark),
      // ✅ Altura de fila de encabezado
      headingRowHeight: 45,
      // ✅ Altura de fila de datos
      dataRowMinHeight: 50,
      dataRowMaxHeight: 50, // o null para sin límite máximo
      // ✅ Eliminar el divisor por defecto
      dividerThickness: 0,
      // ✅ Bordes internos finos
      border: TableBorder(
        horizontalInside: BorderSide(width: 0.5, color: Colors.grey.shade300),
        verticalInside: BorderSide(width: 0.5, color: Colors.grey.shade300),
      ),
      columns: [
        // ✅ Columna fija de Acciones
        DataColumn(
          label: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: const Text(
              'Acciones',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // ✅ Columnas dinámicas
        for (var campo in camposMostrar)
          DataColumn(
            label: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text(
                _getHeaderLabel(campo),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
      ],

      // ✅ Filas de la tabla (paginadas)
      rows: pageItems.asMap().entries.map((entry) {
        final index = entry.key;
        final egreso = entry.value;
        final isEven = index % 2 == 0;

        return DataRow(
          // ✅ Fondo alternado blanco/gris claro
          color: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              return isEven ? Colors.white : Colors.grey[100];
            },
          ),
          cells: [
            // Columna de acciones
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Themes.primary, size: 18),
                    onPressed: () => widget.onEdit(egreso),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete,
                        color: Colors.red.shade900, size: 18),
                    onPressed: () => _confirmarEliminar(
                      context,
                      egreso['id'].toString(),
                    ),
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ),

            // Celdas dinámicas
            for (var campo in camposMostrar)
              DataCell(
                _buildCellContent(egreso, campo),
              ),
          ],
        );
      }).toList(),
    );
  }

  /// Construye el contenido de una celda con manejo de desbordamiento
  Widget _buildCellContent(Map<String, dynamic> egreso, String campo) {
    final cellText = _getCellValueFromMap(egreso, campo);

    // Para columnas específicas que necesitan manejo especial
    switch (campo) {
      case 'fechaPago':
      case 'fecha':
        return Text(
          cellText,
          textAlign: TextAlign.right,
          style: const TextStyle(color: Colors.black87),
        );
      case 'valor':
        return Text(
          cellText,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        );
      default:
        return Text(
          cellText,
          textAlign: TextAlign.right,
          style: const TextStyle(color: Colors.black87),
        );
    }
  }

  /// Obtiene el texto adecuado para el encabezado de la columna
  String _getHeaderLabel(String campo) {
    switch (campo) {
      case 'fechaPago':
        return 'Fecha de Pago';
      case 'quincena':
        return 'Periodo';
      case 'categoria':
        return 'Categoría';
      case 'descripcion':
        return 'Descripción';
      default:
        // Convierte el nombre del campo a formato legible (ej: "valor" -> "Valor")
        return campo[0].toUpperCase() + campo.substring(1);
    }
  }

  /// 📌 Diálogo de confirmación para eliminar egreso
  void _confirmarEliminar(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar egreso'),
        content:
            const Text('¿Estás seguro de que deseas eliminar este egreso?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete(id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  /// 📌 Obtiene el valor que se mostrará en la celda según la columna
  String _getCellValueFromMap(Map<String, dynamic> egreso, String column) {
    final formatoFecha = DateFormat('dd/MM/yyyy');

    switch (column) {
      case 'Periodo':
      case 'quincena':
        return _formatearPeriodo(egreso['quincena']);
      case 'Fecha':
      case 'fecha':
        final v = egreso['fecha'];
        // ✅ Manejo de valores nulos
        if (v == null) return 'N/A';
        if (v is Timestamp) return formatoFecha.format(v.toDate());
        if (v is DateTime) return formatoFecha.format(v);
        return v?.toString() ?? 'N/A';
      case 'Fecha Pago':
      case 'fechaPago':
        final v = egreso['fechaPago'];
        // ✅ Manejo de valores nulos
        if (v == null) return 'N/A';
        if (v is Timestamp) return formatoFecha.format(v.toDate());
        if (v is DateTime) return formatoFecha.format(v);
        return v?.toString() ?? 'N/A';
      case 'Categoría':
      case 'categoria':
        return egreso['categoria']?.toString() ?? '';
      case 'Concepto':
      case 'concepto':
        return egreso['concepto']?.toString() ?? '';
      case 'Valor':
      case 'valor':
        final v = egreso['valor'];
        if (v == null) return '';
        if (v is num) return UIHelpers.formatCurrency(v.toDouble());
        final parsed = num.tryParse(v.toString());
        return parsed != null
            ? UIHelpers.formatCurrency(parsed.toDouble())
            : v.toString();
      case 'Descripción':
      case 'descripcion':
        return egreso['descripcion']?.toString() ?? '';
      case 'Estado':
      case 'estado':
        return egreso['estado']?.toString() ?? '';
      default:
        return egreso[column]?.toString() ?? '';
    }
  }

  /// 📌 Traducción del campo quincena
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

  /// Construye un paginador responsivo que se adapta al tamaño de la pantalla
  Widget _buildResponsivePagination(
    int total,
    int totalPages,
    int safePage,
    int start,
    int end,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determinamos si hay suficiente espacio para mostrar todos los controles
        final bool hasEnoughSpace = constraints.maxWidth > 500;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Texto de rango mostrado (siempre visible)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Mostrando ${start + 1} - $end de $total',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Controles de paginación
            Expanded(
              flex: 3,
              child: hasEnoughSpace
                  ? _buildFullPaginationControls(totalPages, safePage)
                  : _buildCompactPaginationControls(totalPages, safePage),
            ),
          ],
        );
      },
    );
  }

  /// Construye los controles de paginación completos (para pantallas grandes)
  Widget _buildFullPaginationControls(int totalPages, int safePage) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selector de filas por página
        DropdownButton<int>(
          value: _rowsPerPage,
          items: _rowsPerPageOptions
              .map((r) => DropdownMenuItem(
                    value: r,
                    child: Text('$r filas'),
                  ))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _rowsPerPage = value;
              _currentPage = 0; // reset a la primera página
            });
          },
        ),

        // Primera página
        IconButton(
          icon: const Icon(Icons.first_page),
          onPressed:
              safePage > 0 ? () => setState(() => _currentPage = 0) : null,
        ),

        // Página anterior
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: safePage > 0
              ? () => setState(() => _currentPage = max(0, safePage - 1))
              : null,
        ),

        // Indicador de página actual
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Página ${_currentPage + 1} de $totalPages',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        // Página siguiente
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: safePage < totalPages - 1
              ? () => setState(
                  () => _currentPage = min(totalPages - 1, safePage + 1))
              : null,
        ),

        // Última página
        IconButton(
          icon: const Icon(Icons.last_page),
          onPressed: safePage < totalPages - 1
              ? () => setState(() => _currentPage = totalPages - 1)
              : null,
        ),
      ],
    );
  }

  /// Construye los controles de paginación compactos (para pantallas pequeñas)
  Widget _buildCompactPaginationControls(int totalPages, int safePage) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selector de filas por página (solo el número)
          DropdownButton<int>(
            value: _rowsPerPage,
            items: _rowsPerPageOptions
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.toString()),
                    ))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _rowsPerPage = value;
                _currentPage = 0; // reset a la primera página
              });
            },
            style: const TextStyle(fontSize: 12),
          ),

          // Botones de navegación compactos
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: safePage > 0
                ? () => setState(() => _currentPage = max(0, safePage - 1))
                : null,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              '${_currentPage + 1}/$totalPages',
              style: const TextStyle(fontSize: 14),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.chevron_right, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: safePage < totalPages - 1
                ? () => setState(
                    () => _currentPage = min(totalPages - 1, safePage + 1))
                : null,
          ),
        ],
      ),
    );
  }
}
