import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/core/data/providers/Ingreso_provider.dart';
import 'package:finances/presentations/screens/ingresos/Ingreso_form.dart';
import 'package:finances/presentations/screens/ingresos/widgets/Ingreso_chart.dart';
import 'package:finances/presentations/screens/ingresos/widgets/ingreso_table.dart';
import 'package:finances/presentations/screens/ingresos/widgets/ingresos_skeleton_loader.dart';
import 'package:finances/presentations/screens/movimientos/widgets/movimientos_empty_state.dart';
import 'package:finances/presentations/theme/theme.dart';

class IngresosTabView extends ConsumerStatefulWidget {
  final Set<String> visibleColumns;
  final Map<String, String> columnMapping;
  final VoidCallback onOpenAddForm;

  const IngresosTabView({
    super.key,
    required this.visibleColumns,
    required this.columnMapping,
    required this.onOpenAddForm,
  });

  @override
  ConsumerState<IngresosTabView> createState() => _IngresosTabViewState();
}

class _IngresosTabViewState extends ConsumerState<IngresosTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _convertIngresosToMap(List<Ingreso> ingresos) {
    return ingresos.map((ingreso) {
      return {
        'id': ingreso.id,
        'quincena': ingreso.quincena,
        'fechaIngreso': ingreso.fechaIngreso,
        'categoria': ingreso.categoria,
        'concepto': ingreso.concepto,
        'valor': ingreso.valor,
      };
    }).toList();
  }

  void _deleteIngreso(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await ref.read(ingresosServiceProvider).eliminarIngreso(user.uid, id);
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
    ref.refresh(ingresosProvider);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ingresosAsync = ref.watch(ingresosProvider);

    return ingresosAsync.when(
      loading: () => const IngresosSkeletonLoader(),
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
                'Error al cargar ingresos: $error',
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
      data: (ingresos) {
        if (ingresos.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshData,
            color: const Color(0xFF26A69A),
            backgroundColor: context.scaffoldBgColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: MovimientosEmptyState(
                  title: 'Sin ingresos registrados',
                  message:
                      'Aún no has registrado ningún ingreso este mes. Registra tu salario, comisiones u otros ingresos para monitorear tu liquidez.',
                  buttonText: 'Registrar primer ingreso',
                  icon: Icons.account_balance_wallet_rounded,
                  accentColor: const Color(0xFF26A69A),
                  onActionPressed: widget.onOpenAddForm,
                ),
              ),
            ),
          );
        }

        final ingresosMap = _convertIngresosToMap(ingresos);

        return RefreshIndicator(
          onRefresh: _refreshData,
          color: const Color(0xFF26A69A),
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
                    'Distribución de Ingresos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.titleColor,
                    ),
                  ),
                ),
                IncomeChart(ingresos: ingresos),
                const SizedBox(height: 24),

                // Sección de tabla de movimientos
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Historial de Ingresos',
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
                          color: const Color(0xFF26A69A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${ingresos.length} registros',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF26A69A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                IngresoTable(
                  ingresos: ingresosMap,
                  onEdit: (ingresoMap) {
                    final fechaIngreso = ingresoMap['fechaIngreso'] is DateTime
                        ? ingresoMap['fechaIngreso'] as DateTime
                        : DateTime.now();

                    final fecha = ingresoMap['fecha'] is DateTime
                        ? ingresoMap['fecha'] as DateTime
                        : DateTime.now();

                    final ingreso = Ingreso(
                      id: ingresoMap['id']?.toString() ?? '',
                      quincena: ingresoMap['quincena']?.toString() ?? '',
                      fechaIngreso: fechaIngreso,
                      fecha: fecha,
                      categoria: ingresoMap['categoria']?.toString() ?? '',
                      concepto: ingresoMap['concepto']?.toString() ?? '',
                      valor: ingresoMap['valor'] is int
                          ? ingresoMap['valor'] as int
                          : int.tryParse(
                                  ingresoMap['valor']?.toString() ?? '0') ??
                              0,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IngresoForm(ingreso: ingreso),
                      ),
                    );
                  },
                  onDelete: _deleteIngreso,
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
