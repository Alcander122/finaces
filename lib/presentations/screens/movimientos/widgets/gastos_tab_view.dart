import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/presentations/screens/egreso/egreso_form.dart';
import 'package:finances/presentations/screens/egreso/widgets/egreso_chart.dart';
import 'package:finances/presentations/screens/egreso/widgets/egreso_table.dart';
import 'package:finances/presentations/screens/egreso/widgets/egresos_skeleton_loader.dart';
import 'package:finances/presentations/screens/movimientos/widgets/movimientos_empty_state.dart';
import 'package:finances/presentations/theme/theme.dart';

class GastosTabView extends ConsumerStatefulWidget {
  final Set<String> visibleColumns;
  final Map<String, String> columnMapping;
  final VoidCallback onOpenAddForm;

  const GastosTabView({
    super.key,
    required this.visibleColumns,
    required this.columnMapping,
    required this.onOpenAddForm,
  });

  @override
  ConsumerState<GastosTabView> createState() => _GastosTabViewState();
}

class _GastosTabViewState extends ConsumerState<GastosTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _convertEgresosToMap(List<Egreso> egresos) {
    return egresos.map((egreso) {
      return {
        'id': egreso.id,
        'quincena': egreso.quincena,
        'fechaPago': egreso.fechaPago,
        'categoria': egreso.categoria,
        'concepto': egreso.concepto,
        'valor': egreso.valor,
        'descripcion': egreso.descripcion,
        'estado': egreso.estado,
      };
    }).toList();
  }

  void _deleteEgreso(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await ref.read(egresoServiceProvider).eliminarEgreso(user.uid, id);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado')),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    // ignore: unused_result
    ref.refresh(egresosProvider);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final egresosAsync = ref.watch(egresosProvider);

    return egresosAsync.when(
      loading: () => const EgresosSkeletonLoader(),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFEF5350), size: 56),
              const SizedBox(height: 16),
              Text(
                'Error al cargar gastos: $error',
                style: TextStyle(
                  color: context.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (egresos) {
        if (egresos.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshData,
            color: const Color(0xFFEF5350),
            backgroundColor: context.scaffoldBgColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: MovimientosEmptyState(
                  title: 'Sin gastos registrados',
                  message:
                      'Aún no has registrado ningún gasto este mes. Lleva el control de tus salidas de dinero registrando tus compras o pagos.',
                  buttonText: 'Registrar primer gasto',
                  icon: Icons.receipt_long_rounded,
                  accentColor: const Color(0xFFEF5350),
                  onActionPressed: widget.onOpenAddForm,
                ),
              ),
            ),
          );
        }

        final egresosMap = _convertEgresosToMap(egresos);

        return RefreshIndicator(
          onRefresh: _refreshData,
          color: const Color(0xFFEF5350),
          backgroundColor: context.scaffoldBgColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 96.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gráfico y análisis
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4.0, vertical: 8.0),
                  child: Text(
                    'Distribución de Gastos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.titleColor,
                    ),
                  ),
                ),
                EgresoChart(egresos: egresos),
                const SizedBox(height: 24),

                // Sección de tabla de movimientos
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Historial de Gastos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.titleColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${egresos.length} registros',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF5350),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                EgresoTable(
                  egresos: egresosMap,
                  onEdit: (egresoMap) {
                    final fechaPago = egresoMap['fechaPago'] is DateTime
                        ? egresoMap['fechaPago'] as DateTime
                        : DateTime.now();

                    final fecha = egresoMap['fecha'] is DateTime
                        ? egresoMap['fecha'] as DateTime
                        : DateTime.now();

                    final egreso = Egreso(
                      id: egresoMap['id']?.toString() ?? '',
                      quincena: egresoMap['quincena']?.toString() ?? '',
                      fechaPago: fechaPago,
                      fecha: fecha,
                      categoria: egresoMap['categoria']?.toString() ?? '',
                      concepto: egresoMap['concepto']?.toString() ?? '',
                      valor: egresoMap['valor'] is int
                          ? egresoMap['valor'] as int
                          : int.tryParse(
                                  egresoMap['valor']?.toString() ?? '0') ??
                              0,
                      descripcion: egresoMap['descripcion']?.toString() ?? '',
                      estado: egresoMap['estado']?.toString() ?? '',
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EgresoForm(egreso: egreso),
                      ),
                    );
                  },
                  onDelete: _deleteEgreso,
                  camposVisibles: widget.visibleColumns
                      .map((col) => widget.columnMapping[col]!)
                      .toList(),
                  userID: FirebaseAuth.instance.currentUser?.uid ?? '',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
