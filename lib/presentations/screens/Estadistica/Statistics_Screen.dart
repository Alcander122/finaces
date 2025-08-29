
import '../../../core/data/models/filter.dart';
import 'package:finances/core/data/providers/ingreso_provider.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/providers/filter_provider.dart';
import 'package:finances/presentations/screens/Estadistica/widgets/activity_chart.dart';
import 'package:finances/presentations/screens/Estadistica/widgets/category_summary.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:intl/intl.dart';
// SOLUCIÓN: Usamos un prefijo para evitar el conflicto de nombres con DateUtils
import 'package:finances/core/data/utils/date_utils.dart' as MyDateUtils;

/// Pantalla principal de estadísticas que muestra:
/// - Actividad financiera
/// - Filtros (mensual, trimestral, anual, personalizado)
/// - Tarjetas de resumen (ingresos, gastos, balance)
/// - Resumen por categoría
class StatisticScreen extends ConsumerStatefulWidget {
  const StatisticScreen({super.key});

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends ConsumerState<StatisticScreen> {
  DateTimeRange? selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Observamos los proveedores de ingresos y egresos filtrados
    final ingresosAsync = ref.watch(filteredIngresosProvider);
    final egresosAsync = ref.watch(filteredEgresosProvider);

    return Scaffold(
      backgroundColor: Themes.light,
      appBar: const AppBarFinances(
        title: 'Estadistica',
        showProfileIcon: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFinancialActivitySection(),
                const SizedBox(height: 8),
                _buildFilterRow(),
                const SizedBox(height: 12),
                _buildFinancialCards(ingresosAsync, egresosAsync),
                const SizedBox(height: 16),
                _buildCategorySection(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye la sección del gráfico de actividad financiera
  Widget _buildFinancialActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividad Financiera',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: ActivityChart(),
          ),
        )
      ],
    );
  }

  /// Construye la fila de botones para seleccionar el tipo de filtro
  Widget _buildFilterRow() {
    // Obtenemos el tipo de filtro actual para mostrar el estado seleccionado
    final currentFilter = ref.watch(filterProvider).type;

    return SizedBox(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'Mensual',
              isSelected: currentFilter == FilterType.monthly,
              onTap: () => _changeFilter(FilterType.monthly),
              color: Colors.purple,
            ),
            _buildFilterChip(
              label: 'Anual',
              isSelected: currentFilter == FilterType.annual,
              onTap: () => _changeFilter(FilterType.annual),
              color: Colors.blue,
            ),
            _buildFilterChip(
              label: 'Trimestral',
              isSelected: currentFilter == FilterType.quarterly,
              onTap: () => _changeFilter(FilterType.quarterly),
              color: Colors.green,
            ),
            _buildCustomFilterChip(currentFilter),
          ],
        ),
      ),
    );
  }

  /// Construye un botón individual de filtro
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: color.withValues(alpha: 0.2),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? color : Colors.grey[300]!,
        ),
      ),
    );
  }

  /// Construye el botón especial para filtro personalizado
  Widget _buildCustomFilterChip(FilterType currentFilter) {
    final isCustomSelected = currentFilter == FilterType.custom;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Row(
          children: [
            Icon(Icons.calendar_month,
                size: 18,
                color: isCustomSelected ? Colors.orange : Colors.grey),
            const SizedBox(width: 6),
            const Text('Personalizado'),
          ],
        ),
        selected: isCustomSelected,
        onSelected: (_) => selectDateRange(),
        selectedColor: Colors.orange.withValues(alpha: 0.2),
        checkmarkColor: Colors.orange,
        labelStyle: TextStyle(
          color: isCustomSelected ? Colors.orange : Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(
          color: isCustomSelected ? Colors.orange : Colors.grey[300]!,
        ),
      ),
    );
  }

  /// Construye las tarjetas con datos de Ingresos, Gastos y Balance
  Widget _buildFinancialCards(
      AsyncValue<double> ingresos, AsyncValue<double> gastos) {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          Expanded(
            child: _buildFinanceCard(
              title: 'Ingresos',
              value: ingresos,
              color: Colors.green,
              icon: Icons.trending_up,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFinanceCard(
              title: 'Gastos',
              value: gastos,
              color: Colors.red,
              icon: Icons.trending_down,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child:
                _buildBalanceCard(), // Asegúrate de que este método no use width.
          ),
        ],
      ),
    );
  }

  /// Construye una tarjeta individual de estadística
  Widget _buildFinanceCard({
    required String title,
    required AsyncValue<double> value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: value.when(
          // CORRECCIÓN: Especificamos explícitamente los parámetros nombrados
          data: (data) => _buildCardContent(title, icon, color, data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const Text("Error al cargar datos"),
        ),
      ),
    );
  }

  /// Contenido interno de cada tarjeta
  Widget _buildCardContent(
      String title, IconData icon, Color color, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, // Centrado horizontal
      mainAxisAlignment: MainAxisAlignment.center, // Centrado vertical
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textAlign:
              TextAlign.center, // Asegura que el texto también esté centrado
        ),
        const SizedBox(height: 8),
        Text(
          '\$${NumberFormat('#,##0', 'es_CO').format(amount)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Construye la tarjeta del balance general
  Widget _buildBalanceCard() {
    return SizedBox(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ref.watch(filteredIngresosProvider).when(
                // CORRECCIÓN: Especificamos explícitamente los parámetros nombrados
                data: (ing) => ref.watch(filteredEgresosProvider).when(
                      data: (gas) => _buildBalanceContent(ing - gas),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) =>
                          const Text("Error en gastos"),
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => const Text("Error en ingresos"),
              ),
        ),
      ),
    );
  }

  /// Contenido dinámico de la tarjeta de balance
  Widget _buildBalanceContent(double balance) {
    final color = balance >= 0 ? Colors.blue : Colors.red;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              balance >= 0 ? Icons.account_balance_wallet : Icons.warning,
              color: color,
              size: 20,
            ),
          ),
        ),
        Flexible(
          child: const Text(
            'Balance',
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        Flexible(
          child: Text(
            formatCurrency(balance),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Construye la sección de resumen por categoría
  Widget _buildCategorySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen por Categoría',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(50),
                spreadRadius: 2,
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: CategorySummary(
            onCategoryTap: (category, isExpense) {
              Navigator.pushNamed(
                context,
                AppRoutes.categoryDetails,
                arguments: {
                  'category': category,
                  'filter': ref.read(filterProvider),
                  'isExpense': isExpense,
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Abre el selector de rango de fechas y actualiza el filtro
  void selectDateRange() async {
    final initialDate = DateTime.now().subtract(const Duration(days: 30));
    final firstDate = DateTime.now().subtract(const Duration(days: 365));
    final lastDate = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: initialDate, end: DateTime.now()),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      DateTime startDate = picked.start;
      DateTime endDate = picked.end;
      // Ajustamos la fecha final al último momento del día
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      ref.read(filterProvider.notifier).update((state) => state.copyWith(
            type: FilterType.custom,
            startDate: startDate,
            endDate: endDate,
          ));

      // Agregamos un log para verificar las fechas seleccionadas
     /* print(
          'Filtro personalizado: ${startDate.toString()} - ${endDate.toString()}');*/
    }
  }

  /// CAMBIO CRÍTICO: Método modificado para calcular las fechas correctas
  ///
  /// ANTES: Establecía startDate y endDate en null, lo que impedía que los proveedores
  ///        de datos filtrados obtuvieran los datos correctos para el resumen por categoría
  ///
  /// AHORA: Calcula las fechas adecuadas para cada tipo de filtro usando DateUtils
  ///
  /// IMPORTANTE: Este cambio es esencial para que el resumen por categoría se actualice
  ///             correctamente cuando el usuario selecciona un filtro diferente
  void _changeFilter(FilterType type) {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    // SOLUCIÓN: Usamos el prefijo MyDateUtils para referirnos a nuestra clase DateUtils
    // Esto evita el conflicto con la clase DateUtils de Flutter
    switch (type) {
      case FilterType.monthly:
        // Obtiene el primer y último día del mes actual
        startDate = MyDateUtils.DateUtils.getStartOfMonth(now);
        endDate = MyDateUtils.DateUtils.getEndOfMonth(now);
        break;
      case FilterType.quarterly:
        // Usa el trimestre móvil (últimos 3 meses completos)
        // Ejemplo: Si hoy es agosto, devuelve mayo, junio y julio
        // Si es enero, devuelve octubre, noviembre y diciembre del año anterior
        startDate = MyDateUtils.DateUtils.getStartOfRollingQuarter(now);
        endDate = MyDateUtils.DateUtils.getEndOfRollingQuarter(now);
        break;
      case FilterType.annual:
        // Obtiene el primer y último día del año actual
        startDate = MyDateUtils.DateUtils.getStartOfYear(now);
        endDate = MyDateUtils.DateUtils.getEndOfYear(now);
        break;
      case FilterType.custom:
        // Para personalizado, mantenemos las fechas actuales si existen
        // Esto evita perder el rango seleccionado previamente
        final currentFilter = ref.read(filterProvider);
        startDate = currentFilter.startDate;
        endDate = currentFilter.endDate;
        break;
    }

    // Agregamos logs para depurar y verificar que las fechas se calculan correctamente
   /* print('Cambiando filtro a: $type');
    if (startDate != null && endDate != null) {
      print(
          'Rango de fechas calculado: ${startDate.toString()} - ${endDate.toString()}');
    } else {
      print('Sin rango de fechas definido');
    }*/

    // Actualizamos el estado del filtro con las fechas calculadas
    // Esto notificará a todos los widgets que están observando filterProvider
    // y activará la reconstrucción necesaria para mostrar los datos actualizados
    ref.read(filterProvider.notifier).update((state) => state.copyWith(
          type: type,
          startDate: startDate,
          endDate: endDate,
        ));
  }

  /// Formatea un número a formato de moneda local (COP)
  String formatCurrency(double value) {
    final formatter = NumberFormat.decimalPattern('es_CO');
    return '\$${formatter.format(value)}';
  }

  /// Título principal de la sección
  Widget buildHeaderSection(ThemeData theme) {
    return Text(
      'Balance General',
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.blueGrey[800],
      ),
    );
  }
}
