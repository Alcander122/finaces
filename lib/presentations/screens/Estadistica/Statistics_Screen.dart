// statistics_screen.dart
import 'package:finances/core/data/providers/Ingreso_provider.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/presentations/screens/Estadistica/widgets/activity_chart.dart';
import 'package:finances/presentations/screens/Estadistica/widgets/category_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:finances/core/data/models/filter.dart';
import 'package:finances/core/data/providers/filter_provider.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  DateTimeRange? _selectedDateRange;

  void _selectDateRange() async {
    final initialDate = DateTime.now().subtract(const Duration(days: 30));
    final firstDate = DateTime.now().subtract(const Duration(days: 365));
    final lastDate = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: initialDate, end: DateTime.now()),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && picked.start != null && picked.end != null) {
      ref.read(filterProvider.notifier).update((state) => state.copyWith(
            type: FilterType.custom,
            startDate: picked.start,
            endDate: picked.end,
          ));
    }
  }

  void _changeFilter(FilterType type) {
    if (type == FilterType.monthly) {
      ref.read(filterProvider.notifier).update((state) => state.copyWith(
            type: FilterType.monthly,
            startDate: null,
            endDate: null,
          ));
    } else if (type == FilterType.quarterly) {
      ref.read(filterProvider.notifier).update((state) => state.copyWith(
            type: FilterType.quarterly,
            startDate: null,
            endDate: null,
          ));
    } else if (type == FilterType.annual) {
      ref.read(filterProvider.notifier).update((state) => state.copyWith(
            type: FilterType.annual,
            startDate: null,
            endDate: null,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Filter filter = ref.watch(filterProvider);
    final ingresosAsync = ref.watch(filteredIngresosProvider);
    final gastosAsync = ref.watch(filteredEgresosProvider);

    return Scaffold(
      appBar: AppBarFinances(
        title: 'Estadísticas Financieras',
        showBackButton: true,
        showProfileAction: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                'Balance General',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _changeFilter(FilterType.annual),
                    child: const Text('Anual'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _changeFilter(FilterType.quarterly),
                    child: const Text('Trimestral'),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: _selectDateRange,
                    child: const Text('Seleccionar rango'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryCard(
                  title: 'Ingresos',
                  asyncValue: ingresosAsync,
                  icon: Icons.arrow_upward,
                  color: Colors.green,
                ),
                _buildSummaryCard(
                  title: 'Gastos',
                  asyncValue: gastosAsync,
                  icon: Icons.arrow_downward,
                  color: Colors.red,
                ),
                _buildBalanceCard(
                  ingresosAsync: ingresosAsync,
                  gastosAsync: gastosAsync,
                ),
              ],
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                'Actividad Financiera',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            const ActivityChart(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                'Resumen por Categoría',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            const CategorySummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required AsyncValue<double> asyncValue,
    required IconData icon,
    required Color color,
  }) {
    return asyncValue.when(
      data: (data) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 5),
                Text(title, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 5),
                Text(
                  '\$${data.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
      loading: () {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 5),
                Text(title, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 5),
                const Text(
                  '\$0.00',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 5),
                Text(title, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 5),
                const Text(
                  '\$0.00',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard({
    required AsyncValue<double> ingresosAsync,
    required AsyncValue<double> gastosAsync,
  }) {
    return ingresosAsync.when(
      data: (ingresosData) {
        return gastosAsync.when(
          data: (gastosData) {
            double balance = ingresosData - gastosData;
            Color balanceColor = balance >= 0 ? Colors.blue : Colors.red;

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(
                        Colors.transparent,
                        balanceColor,
                        0.2,
                      )!,
                      Color.lerp(
                        Colors.transparent,
                        balanceColor,
                        0.1,
                      )!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.trending_up, color: balanceColor, size: 20),
                    const SizedBox(height: 5),
                    const Text('Balance', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 5),
                    Text(
                      '\$${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () {
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(
                        Colors.transparent,
                        Colors.blue,
                        0.2,
                      )!,
                      Color.lerp(
                        Colors.transparent,
                        Colors.blue,
                        0.1,
                      )!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.trending_up, color: Colors.blue, size: 20),
                    const SizedBox(height: 5),
                    const Text('Balance', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 5),
                    const Text(
                      '\$0.00',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
          error: (error, stackTrace) {
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(
                        Colors.transparent,
                        Colors.blue,
                        0.2,
                      )!,
                      Color.lerp(
                        Colors.transparent,
                        Colors.blue,
                        0.1,
                      )!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.trending_up, color: Colors.blue, size: 20),
                    const SizedBox(height: 5),
                    const Text('Balance', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 5),
                    const Text(
                      '\$0.00',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [
                  Color.lerp(
                    Colors.transparent,
                    Colors.blue,
                    0.2,
                  )!,
                  Color.lerp(
                    Colors.transparent,
                    Colors.blue,
                    0.1,
                  )!,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.trending_up, color: Colors.blue, size: 20),
                const SizedBox(height: 5),
                const Text('Balance', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 5),
                const Text(
                  '\$0.00',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [
                  Color.lerp(
                    Colors.transparent,
                    Colors.blue,
                    0.2,
                  )!,
                  Color.lerp(
                    Colors.transparent,
                    Colors.blue,
                    0.1,
                  )!,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.trending_up, color: Colors.blue, size: 20),
                const SizedBox(height: 5),
                const Text('Balance', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 5),
                const Text(
                  '\$0.00',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
