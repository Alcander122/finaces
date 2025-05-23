// lib/presentations/screens/Estadistica/Statistics_Screen.dart

import 'package:finances/core/data/models/filter.dart';
import 'package:finances/core/data/providers/ingreso_provider.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/providers/filter_provider.dart';
import 'package:finances/presentations/screens/Estadistica/widgets/activity_chart.dart';
import 'package:finances/presentations/screens/Estadistica/widgets/category_summary.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class StatisticScreen extends ConsumerStatefulWidget {
  const StatisticScreen({super.key});

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends ConsumerState<StatisticScreen> {
  DateTimeRange? selectedDateRange;

  // Abre el selector de rango de fechas y actualiza el filtro
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

  // Cambia el tipo de filtro y reinicia las fechas personalizadas si es necesario
  void _changeFilter(FilterType type) {
    ref.read(filterProvider.notifier).update((state) => state.copyWith(
          type: type,
          startDate: null,
          endDate: null,
        ));
  }

  // Formatea un número a formato de moneda local
  String formatCurrency(double value) {
    final formatter = NumberFormat.decimalPattern('es_CO');
    return '\$${formatter.format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ingresosAsync = ref.watch(filteredIngresosProvider);
    final egresosAsync = ref.watch(filteredEgresosProvider);

    return Scaffold(
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
                _buildHeaderSection(theme),
                const SizedBox(height: 24),
                _buildFilterRow(),
                const SizedBox(height: 24),
                _buildFinancialCards(ingresosAsync, egresosAsync),
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

  // Título principal de la sección
  Widget _buildHeaderSection(ThemeData theme) {
    return Text(
      'Balance General',
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.blueGrey[800],
      ),
    );
  }

  // Fila de botones para seleccionar el tipo de filtro
  Widget _buildFilterRow() {
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

  // Botón individual de filtro
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

  // Botón especial para filtro personalizado
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

  // Tarjetas con datos de Ingresos, Gastos y Balance
  Widget _buildFinancialCards(
      AsyncValue<double> ingresos, AsyncValue<double> gastos) {
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

  // Construye una tarjeta individual de estadística
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

  // Contenido interno de cada tarjeta
  Widget _buildCardContent(
      String title, IconData icon, Color color, double value) {
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

  // Tarjeta del balance general
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
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text("Error en gastos"),
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text("Error en ingresos"),
              ),
        ),
      ),
    );
  }

  // Contenido dinámico de la tarjeta de balance
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

  // Sección del gráfico de actividad financiera
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
                color: Colors.grey.withAlpha(50),
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

  // Resumen por categoría
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
}
