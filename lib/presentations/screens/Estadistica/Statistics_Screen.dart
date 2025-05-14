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

  void _changeFilter(FilterType type) {
    ref.read(filterProvider.notifier).update((state) => state.copyWith(
          type: type,
          startDate: null,
          endDate: null,
        ));
  }

  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(filterProvider);
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
              children: [
                _buildHeaderSection(theme),
                const SizedBox(height: 32),
                _buildFilterChips(),
                const SizedBox(height: 32),
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

  Widget _buildFilterChips() {
    final currentFilter = ref.watch(filterProvider).type;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        InputChip(
          label: const Text('Anual'),
          selected: currentFilter == FilterType.annual,
          onSelected: (_) => _changeFilter(FilterType.annual),
          backgroundColor: Colors.white,
          selectedColor: Colors.blue[100],
          labelStyle: TextStyle(
            color: currentFilter == FilterType.annual
                ? Colors.blue[800]
                : Colors.grey[700],
          ),
        ),
        InputChip(
          label: const Text('Trimestral'),
          selected: currentFilter == FilterType.quarterly,
          onSelected: (_) => _changeFilter(FilterType.quarterly),
          backgroundColor: Colors.white,
          selectedColor: Colors.green[100],
          labelStyle: TextStyle(
            color: currentFilter == FilterType.quarterly
                ? Colors.green[800]
                : Colors.grey[700],
          ),
        ),
        ActionChip(
          label: const Text('Personalizado'),
          onPressed: selectDateRange,
          avatar: const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
          backgroundColor: Colors.white,
          labelStyle: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildFinancialCards(AsyncValue<double> ingresos, AsyncValue<double> gastos) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = (constraints.maxWidth - 48) / 3;  // Ajustamos el espacio para 3 cards
        return Row(  // Usamos Row para alinear los cards en una línea
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFinanceCard(
              title: 'Ingresos',
              value: ingresos,
              color: Colors.green,
              icon: Icons.trending_up,
              width: cardWidth,
            ),
            SizedBox(width: 16),  // Espacio entre cards
            _buildFinanceCard(
              title: 'Gastos',
              value: gastos,
              color: Colors.red,
              icon: Icons.trending_down,
              width: cardWidth,
            ),
            SizedBox(width: 16),
            _buildBalanceCard(width: cardWidth),
          ],
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: value.when(
            data: (data) => _buildCardContent(title, icon, color, data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text("Error loading data"),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(String title, IconData icon, Color color, double value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formatCurrency(value),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.fade,
        ),
      ],
    );
  }

  Widget _buildBalanceCard({required double width}) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ref.watch(filteredIngresosProvider).when(
            data: (ing) => ref.watch(filteredEgresosProvider).when(
              data: (gas) => _buildBalanceContent(ing - gas),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text("Error loading expenses"),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text("Error loading income"),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceContent(double balance) {
    final color = balance >= 0 ? Colors.blue : Colors.red;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            balance >= 0 ? Icons.account_balance_wallet : Icons.warning,
            color: color,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Balance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formatCurrency(balance),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Actividad Financiera',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 280,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
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
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Resumen por Categoría',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: CategorySummary(),
        ),
      ],
    );
  }
}