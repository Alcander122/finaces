import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/providers/Ingreso_provider.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/screens/Estadistica/Statistics_Screen.dart';
import 'package:finances/presentations/screens/egreso/egreso_form.dart';
import 'package:finances/presentations/screens/ingresos/Ingreso_form.dart';
import 'package:finances/presentations/screens/movimientos/widgets/contextual_movimientos_fab.dart';
import 'package:finances/presentations/screens/movimientos/widgets/gastos_tab_view.dart';
import 'package:finances/presentations/screens/movimientos/widgets/ingresos_tab_view.dart';
import 'package:finances/presentations/screens/movimientos/widgets/movimientos_segmented_tab_bar.dart';
import 'package:finances/presentations/widgets/column_selection_dialog.dart';
import 'package:finances/presentations/theme/theme.dart';

class MovimientosScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const MovimientosScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  ConsumerState<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends ConsumerState<MovimientosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Columnas para Gastos ---
  final List<String> _allGastosColumns = [
    'Periodo',
    'Fecha Pago',
    'Categoría',
    'Concepto',
    'Valor',
    'Descripción',
    'Estado',
  ];

  Set<String> _visibleGastosColumns = {
    'Periodo',
    'Fecha Pago',
    'Valor',
    'Estado',
  };

  final Map<String, String> _gastosColumnMapping = {
    'Periodo': 'quincena',
    'Fecha Pago': 'fechaPago',
    'Categoría': 'categoria',
    'Concepto': 'concepto',
    'Valor': 'valor',
    'Descripción': 'descripcion',
    'Estado': 'estado',
  };

  // --- Columnas para Ingresos ---
  final List<String> _allIngresosColumns = [
    'Periodo',
    'Fecha Ingreso',
    'Categoría',
    'Concepto',
    'Valor',
  ];

  Set<String> _visibleIngresosColumns = {
    'Periodo',
    'Fecha Ingreso',
    'Categoría',
    'Valor',
  };

  final Map<String, String> _ingresosColumnMapping = {
    'Periodo': 'quincena',
    'Fecha Ingreso': 'fechaIngreso',
    'Categoría': 'categoria',
    'Concepto': 'concepto',
    'Valor': 'valor',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showColumnSelectionDialog() async {
    final isGastos = _tabController.index == 0;
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (context) => ColumnSelectionDialog(
        selectedColumns:
            isGastos ? _visibleGastosColumns : _visibleIngresosColumns,
        allColumns: isGastos ? _allGastosColumns : _allIngresosColumns,
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        if (isGastos) {
          _visibleGastosColumns = selected;
        } else {
          _visibleIngresosColumns = selected;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isGastos = _tabController.index == 0;

    final egresosAsync = ref.watch(egresosProvider);
    final ingresosAsync = ref.watch(ingresosProvider);
    final totalGastosAsync = ref.watch(totalEgresoMesActualProvider);
    final totalIngresosAsync = ref.watch(totalIngresosMesActualProvider);

    final gastosCount = egresosAsync.value?.length ?? 0;
    final ingresosCount = ingresosAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: context.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF003366),
        elevation: 3,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Regresar',
              )
            : null,
        title: const Text(
          'Movimientos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            tooltip: isGastos
                ? 'Filtrar columnas de Gastos'
                : 'Filtrar columnas de Ingresos',
            onPressed: _showColumnSelectionDialog,
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.chartPie,
                color: Colors.white, size: 18),
            tooltip: 'Estadísticas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatisticScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton:
          ContextualMovimientosFab(tabController: _tabController),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Resumen de cabecera reactivo
            SliverToBoxAdapter(
              child: _buildHeaderSummary(
                context: context,
                isDark: isDark,
                isGastos: isGastos,
                totalGastosAsync: totalGastosAsync,
                totalIngresosAsync: totalIngresosAsync,
              ),
            ),
            // Selector de pestañas Segmented
            SliverToBoxAdapter(
              child: MovimientosSegmentedTabBar(
                tabController: _tabController,
                gastosCount: gastosCount,
                ingresosCount: ingresosCount,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Pestaña 1: Gastos
            GastosTabView(
              visibleColumns: _visibleGastosColumns,
              columnMapping: _gastosColumnMapping,
              onOpenAddForm: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EgresoForm(egreso: null),
                  ),
                );
              },
            ),
            // Pestaña 2: Ingresos
            IngresosTabView(
              visibleColumns: _visibleIngresosColumns,
              columnMapping: _ingresosColumnMapping,
              onOpenAddForm: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IngresoForm(ingreso: null),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSummary({
    required BuildContext context,
    required bool isDark,
    required bool isGastos,
    required AsyncValue<double> totalGastosAsync,
    required AsyncValue<double> totalIngresosAsync,
  }) {
    final activeColor =
        isGastos ? const Color(0xFFEF5350) : const Color(0xFF26A69A);
    final activeLabel = isGastos ? 'Total Gastos (Mes)' : 'Total Ingresos (Mes)';
    final activeAsync = isGastos ? totalGastosAsync : totalIngresosAsync;

    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono circular con color contextual
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGastos
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: activeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 4),
                activeAsync.when(
                  data: (amount) => Text(
                    UIHelpers.formatCurrency(amount),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  loading: () => SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: activeColor,
                    ),
                  ),
                  error: (_, __) => Text(
                    r'$0',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chip indicador interactivo para cambiar al otro tab
          InkWell(
            onTap: () {
              _tabController.animateTo(isGastos ? 1 : 0);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activeColor.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isGastos ? 'Ver Ingresos' : 'Ver Gastos',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: activeColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: activeColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
