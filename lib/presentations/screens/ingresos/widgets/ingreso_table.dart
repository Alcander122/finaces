import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';

class IngresoTable extends StatefulWidget {
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
  State<IngresoTable> createState() => _IngresoTableState();
}

class _IngresoTableState extends State<IngresoTable> {
  int _currentPage = 0;
  int _itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    if (widget.ingresos.isEmpty) {
      return Center(
        child: Text(
          'No hay ingresos disponibles',
          style: TextStyle(color: context.isDarkMode ? Colors.white70 : Colors.black87),
        ),
      );
    }

    final totalItems = widget.ingresos.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, totalItems);
    final paginatedItems = widget.ingresos.sublist(startIndex, endIndex);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            isDesktop
                ? _buildDesktopTable(paginatedItems)
                : _buildMobileList(paginatedItems),
            const SizedBox(height: 16),
            PaginationControl(
              currentPage: _currentPage,
              totalPages: totalPages,
              itemsPerPage: _itemsPerPage,
              totalItems: totalItems,
              onPageChanged: (page) => setState(() => _currentPage = page),
              onItemsPerPageChanged: (newItemsPerPage) => setState(() {
                _itemsPerPage = newItemsPerPage;
                _currentPage = 0;
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileList(List<Map<String, dynamic>> items) {
    final isDark = context.isDarkMode;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final ingreso = items[index];
        final id = ingreso['id'].toString();
        final concepto = ingreso['concepto']?.toString() ?? 'Sin concepto';
        final categoria = ingreso['categoria']?.toString() ?? 'Otros';
        final valor = ingreso['valor'] != null ? (ingreso['valor'] as num).toDouble() : 0.0;
        
        DateTime fecha = DateTime.now();
        if (ingreso['fechaIngreso'] != null) {
          if (ingreso['fechaIngreso'] is Timestamp) {
            fecha = (ingreso['fechaIngreso'] as Timestamp).toDate();
          } else if (ingreso['fechaIngreso'] is DateTime) {
            fecha = ingreso['fechaIngreso'];
          } else if (ingreso['fechaIngreso'] is String) {
            fecha = DateTime.parse(ingreso['fechaIngreso']);
          }
        }
        final fechaFormateada = DateFormat('dd MMM yyyy').format(fecha);

        return Dismissible(
          key: Key(id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Themes.red,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await _showConfirmDeleteDialog(context);
          },
          onDismissed: (direction) => widget.onDelete(id),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showingresoOptions(context, ingreso),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: context.colors.primary.withValues(alpha: 0.15),
                      child: Icon(Icons.shopping_bag, color: context.colors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.camposVisibles.contains('concepto')) ...[
                            Text(
                              concepto,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (widget.camposVisibles.contains('categoria') || widget.camposVisibles.contains('fechaIngreso'))
                            Text(
                              [
                                if (widget.camposVisibles.contains('categoria')) categoria,
                                if (widget.camposVisibles.contains('fechaIngreso')) fechaFormateada
                              ].join(' • '),
                              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                            ),
                          ...widget.camposVisibles
                              .where((c) => !['concepto', 'categoria', 'fechaIngreso', 'valor'].contains(c))
                              .map((campo) => Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_formatearNombreCampo(campo)}: ',
                                          style: TextStyle(
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Expanded(
                                          child: DefaultTextStyle(
                                            style: TextStyle(
                                              color: isDark ? Colors.grey[200] : Colors.grey[800]!,
                                              fontSize: 13,
                                            ),
                                            child: _formatearCelda(campo, ingreso[campo])
                                          )
                                        ),
                                      ],
                                    ),
                                  )),
                        ],
                      ),
                    ),
                    if (widget.camposVisibles.contains('valor'))
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          UIHelpers.formatCurrency(valor),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.greenAccent : Themes.green,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showingresoOptions(BuildContext context, Map<String, dynamic> ingreso) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              ListTile(
                leading: Icon(Icons.edit, color: context.colors.primary),
                title: const Text('Editar Ingreso'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onEdit(ingreso);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Themes.red),
                title: const Text('Eliminar Ingreso'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await _showConfirmDeleteDialog(context);
                  if (confirm == true) {
                    widget.onDelete(ingreso['id'].toString());
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _showConfirmDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ingreso'),
        content: const Text('¿Estás seguro de que deseas eliminar este ingreso? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Themes.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<Map<String, dynamic>> items) {
    final Set<String> camposDisponibles = widget.ingresos.first.keys.toSet();
    final List<String> camposMostrar = widget.camposVisibles
        .where((campo) => camposDisponibles.contains(campo))
        .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.resolveWith((states) => context.colors.primary),
          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          columns: [
            const DataColumn(label: Text('Acciones')),
            ...camposMostrar.map((campo) => DataColumn(label: Text(_formatearNombreCampo(campo)))),
          ],
          rows: items.map((ingreso) {
            return DataRow(
              cells: [
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: context.colors.primary, size: 20),
                      onPressed: () => widget.onEdit(ingreso),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Themes.red, size: 20),
                      onPressed: () async {
                        final confirm = await _showConfirmDeleteDialog(context);
                        if (confirm == true) {
                          widget.onDelete(ingreso['id'].toString());
                        }
                      },
                    ),
                  ],
                )),
                ...camposMostrar.map((campo) => DataCell(_formatearCelda(campo, ingreso[campo]))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _formatearCelda(String campo, dynamic valor) {
    if (campo == 'fechaIngreso' && valor != null) {
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
      return Text(UIHelpers.formatCurrency((valor as num).toDouble()));
    } else if (campo == 'quincena') {
      return FittedBox(fit: BoxFit.scaleDown, child: Text(_formatearPeriodo(valor)));
    } else {
      return Text(valor?.toString() ?? '');
    }
  }

  String _formatearPeriodo(dynamic valor) {
    switch (valor) {
      case 'Primera': return 'Primera Quincena';
      case 'Segunda': return 'Segunda Quincena';
      case 'Diario': return 'Diario';
      case 'Mensual': return 'Mensual';
      default: return valor?.toString() ?? '';
    }
  }

  String _formatearNombreCampo(String campo) {
    switch (campo) {
      case 'fechaIngreso': return 'Fecha Ingreso';
      case 'quincena': return 'Periodo';
      case 'valor': return 'Valor';
      case 'categoria': return 'Categoría';
      case 'concepto': return 'Concepto';
      case 'descripcion': return 'Descripción';
      case 'estado': return 'Estado';
      default: return campo[0].toUpperCase() + campo.substring(1);
    }
  }
}

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
    final isDark = context.isDarkMode;
    final startItem = currentPage * itemsPerPage + 1;
    final endItem = min(startItem + itemsPerPage - 1, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      alignment: Alignment.center,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Text(
            'Mostrando $startItem - $endItem de $totalItems',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
          ),
          DropdownButton<int>(
            value: itemsPerPage,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Themes.primary,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            items: [5, 10, 25, 50].map((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text(value.toString()),
              );
            }).toList(),
            onChanged: (int? newValue) {
              if (newValue != null) onItemsPerPageChanged(newValue);
            },
            underline: Container(height: 1, color: isDark ? Colors.grey[700] : Colors.grey),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: isDark ? Colors.white70 : Colors.black87),
                onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
              ),
              Text(
                '${currentPage + 1}/$totalPages',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: isDark ? Colors.white70 : Colors.black87),
                onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
