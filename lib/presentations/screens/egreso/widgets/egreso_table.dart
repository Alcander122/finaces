import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';

/// 🔹 Widget principal de la tabla de egresos
class EgresoTable extends StatefulWidget {
  final List<Map<String, dynamic>> egresos; // Lista de egresos desde Firebase
  final void Function(Map<String, dynamic>)
      onEdit; // Acción al editar un egreso
  final void Function(String) onDelete; // Acción al eliminar un egreso
  final List<String> camposVisibles; // Campos configurables para mostrar
  final String userID; // ID del usuario logueado

  const EgresoTable({
    super.key,
    required this.egresos,
    required this.onEdit,
    required this.onDelete,
    required this.camposVisibles,
    required this.userID,
  });

  @override
  State<EgresoTable> createState() => _EgresoTableState();
}

class _EgresoTableState extends State<EgresoTable> {
  int _currentPage = 0; // Página actual
  int _itemsPerPage = 5; // Número de items por página

  @override
  Widget build(BuildContext context) {
    if (widget.egresos.isEmpty) {
      return const Center(child: Text('No hay egresos disponibles'));
    }

    // 🔹 Calcular paginación
    final totalItems = widget.egresos.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, totalItems);
    final paginatedItems = widget.egresos.sublist(startIndex, endIndex);

    // 🔹 Campos disponibles (del primer egreso)
    final Set<String> camposDisponibles = widget.egresos.first.keys.toSet();

    // 🔹 Filtrar solo los campos visibles configurados
    final List<String> camposMostrar = widget.camposVisibles
        .where((campo) => camposDisponibles.contains(campo))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 🔹 Tarjeta que contiene la tabla
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection:
                Axis.horizontal, // Scroll horizontal para muchas columnas
            child: Column(
              children: [
                // 🔹 Encabezado
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Themes.degradientDark, Themes.degradientLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  child: Row(
                    children: [
                      // Columna de acciones
                      const SizedBox(
                        width: 100,
                        child: Center(
                          child: Text(
                            "Acciones",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // 🔹 Campos dinámicos
                      for (var campo in camposMostrar)
                        SizedBox(
                          width: 120,
                          child: Center(
                            child: Text(
                              _formatearNombreCampo(campo),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 🔹 Filas dinámicas de egresos
                for (var egreso in paginatedItems) ...[
                  Container(
                    color: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: Row(
                      children: [
                        // Columna de acciones
                        SizedBox(
                          width: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Tooltip(
                                message: "Actualizar registro",
                                child: IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Themes.primary, size: 18),
                                  onPressed: () => widget.onEdit(egreso),
                                ),
                              ),
                              Tooltip(
                                message: "Eliminar registro",
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Themes.red, size: 18),
                                  onPressed: () => _confirmarEliminar(
                                      context, egreso['id'].toString()),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 🔹 Celdas dinámicas
                        for (var campo in camposMostrar)
                          SizedBox(
                            width: 120,
                            child: Center(
                              child: _formatearCelda(campo, egreso[campo]),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.6, color: Colors.grey),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 🔹 Paginador SIEMPRE visible
        PaginationControl(
          currentPage: _currentPage,
          totalPages: totalPages,
          itemsPerPage: _itemsPerPage,
          totalItems: totalItems,
          onPageChanged: (page) {
            setState(() {
              _currentPage = page;
            });
          },
          onItemsPerPageChanged: (newItemsPerPage) {
            setState(() {
              _itemsPerPage = newItemsPerPage;
              _currentPage = 0;
            });
          },
        ),
      ],
    );
  }

  /// 🔹 Confirmación antes de eliminar
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

  /// 🔹 Formatea los valores de las celdas según el tipo de campo
  Widget _formatearCelda(String campo, dynamic valor) {
    if (campo == 'fechaPago' && valor != null) {
      try {
        DateTime fecha;

        if (valor is Timestamp) {
          fecha = valor.toDate();
        } else if (valor is DateTime) {
          fecha = valor;
        } else if (valor is String) {
          fecha = DateTime.parse(valor);
        } else {
          return Text(valor.toString());
        }

        return Text(DateFormat('dd/MM/yyyy').format(fecha));
      } catch (e) {
        return Text(valor.toString());
      }
    } else if (campo == 'valor' && valor != null) {
      return Text(UIHelpers.formatCurrency(valor.toDouble()));
    } else if (campo == 'quincena') {
      // ✅ Ajuste: evitar salto de línea con FittedBox
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(_formatearPeriodo(valor)),
      );
    } else {
      return Text(valor?.toString() ?? '');
    }
  }

  /// 🔹 Traducción de valores de quincena
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

  /// 🔹 Formatea el nombre de los campos para mostrarlos en el encabezado
  String _formatearNombreCampo(String campo) {
    switch (campo) {
      case 'fechaPago':
        return 'Fecha Pago';
      case 'quincena':
        return 'Periodo';
      case 'valor':
        return 'Valor';
      case 'categoria':
        return 'Categoría';
      case 'concepto':
        return 'Concepto';
      case 'descripcion':
        return 'Descripción';
      case 'estado':
        return 'Estado';
      default:
        return campo[0].toUpperCase() + campo.substring(1);
    }
  }
}

/// 🔹 Componente de control de paginación
class PaginationControl extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final int totalItems;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onItemsPerPageChanged;

  const PaginationControl({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.totalItems,
    required this.onPageChanged,
    required this.onItemsPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final startItem = currentPage * itemsPerPage + 1;
    final endItem = min(startItem + itemsPerPage - 1, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mostrando $startItem - $endItem de $totalItems',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: itemsPerPage,
              items: [5, 10, 25, 50].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  onItemsPerPageChanged(newValue);
                }
              },
              underline: Container(),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 18),
              onPressed:
                  currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
            ),
            Text(
              '${currentPage + 1}/$totalPages',
              style: const TextStyle(fontSize: 10),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 18),
              onPressed: currentPage < totalPages - 1
                  ? () => onPageChanged(currentPage + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
