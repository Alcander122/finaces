// statistics_screen.dart
import 'package:finances/core/data/models/filter.dart';
import 'package:finances/core/data/providers/Ingreso_provider.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/presentations/screens/Estadistica/widgets/activity_chart.dart';
import 'package:finances/presentations/screens/Estadistica/widgets/category_summary.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:finances/core/data/providers/filter_provider.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  DateTimeRange? selectedDateRange;

  // Selección de rango de fechas personalizado
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
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      ref.read(filterProvider.notifier).update((state) => state.copyWith(
            type: FilterType.custom,
            startDate: startDate,
            endDate: endDate,
          ));
    }
  }

  // Cambiar tipo de filtro
  void _changeFilter(FilterType type) {
    ref.read(filterProvider.notifier).update((state) => state.copyWith(
          type: type,
          startDate: null,
          endDate: null,
        ));
  }

  // Formatear valores monetarios
  /*String formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }*/
  String formatCurrency(double value) {
      final formatter = NumberFormat.decimalPattern('es_CO');
      return '\$${formatter.format(value)}';
    }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ingresosAsync = ref.watch(filteredIngresosProvider);
    final gastosAsync = ref.watch(filteredEgresosProvider);

    return Scaffold(
      appBar: AppBarFinances(
        title: 'Estadísticas Financieras',
        showBackButton: true,
        showProfileAction: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildHeaderSection(theme),
                const SizedBox(height: 24),
                _buildFilterRow(),
                const SizedBox(height: 24),
                _buildFinancialCards(ingresosAsync, gastosAsync),
                const SizedBox(height: 40),
                _buildFinancialActivitySection(),
                const SizedBox(height: 40),
                _buildCategorySection(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Text(
      'Balance General',
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.blueGrey[800],
      ),
    );
  }

  Widget _buildFilterRow() {
    final currentFilter = ref.watch(filterProvider).type;
    return SizedBox(
      height: 50,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            children: [
              FilterChip(
                label: const Text('Anual'),
                selected: currentFilter == FilterType.annual,
                onSelected: (value) => _changeFilter(FilterType.annual),
                selectedColor: Colors.blue[100],
                labelStyle: TextStyle(
                  color: currentFilter == FilterType.annual
                      ? Colors.blue[800]
                      : Colors.grey[700],
                ),
              ),
              FilterChip(
                label: const Text('Trimestral'),
                selected: currentFilter == FilterType.quarterly,
                onSelected: (value) => _changeFilter(FilterType.quarterly),
                selectedColor: Colors.green[100],
                labelStyle: TextStyle(
                  color: currentFilter == FilterType.quarterly
                      ? Colors.green[800]
                      : Colors.grey[700],
                ),
              ),
              FilterChip(
                label: const Text('Personalizado'),
                onSelected: (value) => selectDateRange(),
                avatar: const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                labelStyle: const TextStyle(color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFinancialCards(AsyncValue<double> ingresos, AsyncValue<double> gastos) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = (constraints.maxWidth - 16) / 3;
        return SizedBox(
          height: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFinanceCard(
                title: 'Ingresos',
                value: ingresos,
                color: Colors.green,
                icon: Icons.trending_up,
                width: cardWidth,
              ),
              _buildFinanceCard(
                title: 'Gastos',
                value: gastos,
                color: Colors.red,
                icon: Icons.trending_down,
                width: cardWidth,
              ),
              _buildBalanceCard(width: cardWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinanceCard({
    required String title,
    required AsyncValue<double> value,
    required Color color,
    required IconData icon,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: value.when(
            data: (data) => _buildCardContent(title, icon, color, data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text("Error al cargar datos"),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(String title, IconData icon, Color color, double value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        Flexible(
          child: Text(
            formatCurrency(value),
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

  Widget _buildBalanceCard({required double width}) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ref.watch(filteredIngresosProvider).when(
            data: (ing) => ref.watch(filteredEgresosProvider).when(
              data: (gas) => _buildBalanceContent(ing - gas),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text("Error en gastos"),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text("Error en ingresos"),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceContent(double balance) {
    final color = balance >= 0 ? Colors.blue : Colors.red;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
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

  Widget _buildFinancialActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividad Financiera',
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
                color: Colors.grey.withValues(alpha:0.1),
                spreadRadius: 2,
                blurRadius: 8,
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: ActivityChart(),
          ),
        ),
      ],
    );
  }

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
                color: Colors.grey.withValues(alpha:0.1),
                spreadRadius: 2,
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: const CategorySummary(),
        ),
      ],
    );
  }
}

extension DateTimeExtensions on DateTime? {
  String format(String pattern) {
    if (this == null) return '';
    return DateFormat(pattern).format(this!);
  }
}