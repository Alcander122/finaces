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

// Clase principal de la pantalla de estadísticas
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

// Estado de la pantalla de estadísticas
class StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  DateTimeRange? selectedDateRange;

  // Método para seleccionar un rango de fechas
  void selectDateRange() async {
    final initialDate = DateTime.now().subtract(const Duration(
        days: 30)); // Fecha inicial predeterminada (hace 30 días)
    final firstDate = DateTime.now()
        .subtract(const Duration(days: 365)); // Fecha mínima (hace un año)
    final lastDate = DateTime.now(); // Fecha máxima (hoy)

    // Mostrar el selector de rango de fechas
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: initialDate, end: DateTime.now()),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    // Si el usuario seleccionó un rango de fechas
    if (picked != null) {
      DateTime startDate = picked.start; // Fecha de inicio seleccionada
      DateTime endDate = picked.end; // Fecha de fin seleccionada

      // Ajustar endDate al final del día (23:59:59) para incluir todos los datos del último día
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      // Actualizar el filtro con el rango de fechas seleccionado
      ref.read(filterProvider.notifier).update((state) => state.copyWith(
            type: FilterType.custom,
            startDate: startDate,
            endDate: endDate,
          ));
    }
  }

  // Método para cambiar el tipo de filtro (anual, trimestral, etc.)
  void _changeFilter(FilterType type) {
    if (type == FilterType.monthly) {
      // Actualizar el filtro a mensual
      ref.read(filterProvider.notifier).update((state) => state.copyWith(
            type: FilterType.monthly,
            startDate: null,
            endDate: null,
          ));
    } else if (type == FilterType.quarterly) {
      // Actualizar el filtro a trimestral
      ref.read(filterProvider.notifier).update((state) => state.copyWith(
            type: FilterType.quarterly,
            startDate: null,
            endDate: null,
          ));
    } else if (type == FilterType.annual) {
      // Actualizar el filtro a anual
      ref.read(filterProvider.notifier).update((state) => state.copyWith(
            type: FilterType.annual,
            startDate: null,
            endDate: null,
          ));
    }
  }

  // Método para formatear los valores monetarios con separadores de miles y decimales
  String formatCurrency(double value) {
    // Utilizamos NumberFormat para dar formato al valor según el patrón de Colombia
    final formatter = NumberFormat.decimalPattern('es_CO');
    // Devolvemos el valor formateado con un símbolo de dólar al inicio
    return '\$${formatter.format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    // Observar el estado del filtro actual
    final Filter filter = ref.watch(filterProvider);
    // Observar los ingresos filtrados basados en el filtro actual
    final ingresosAsync = ref.watch(filteredIngresosProvider);
    // Observar los gastos filtrados basados en el filtro actual
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
                    onPressed: selectDateRange,
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

  // Método para construir una tarjeta de resumen (Ingresos, Gastos)
  Widget _buildSummaryCard({
    required String title,
    required AsyncValue<double> asyncValue,
    required IconData icon,
    required Color color,
  }) {
    return asyncValue.when(
      data: (data) {
        // Si hay datos, mostrar la tarjeta con el valor formateado
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
                // Usamos formatCurrency para dar formato al valor
                Text(
                  formatCurrency(data),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
      loading: () {
        // Si están cargando los datos, mostrar una tarjeta con valor predeterminado
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
        // Si hay un error, mostrar una tarjeta con valor predeterminado
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

  // Método para construir la tarjeta de balance
  Widget _buildBalanceCard({
    required AsyncValue<double> ingresosAsync,
    required AsyncValue<double> gastosAsync,
  }) {
    return ingresosAsync.when(
      data: (ingresosData) {
        return gastosAsync.when(
          data: (gastosData) {
            // Calcular el balance
            double balance = ingresosData - gastosData;
            // Determinar el color del balance (azul para positivo, rojo para negativo)
            Color balanceColor = balance >= 0 ? Colors.blue : Colors.red;

            // Mostrar la tarjeta de balance con el valor formateado
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
                    // Usamos formatCurrency para dar formato al valor del balance
                    Text(
                      formatCurrency(balance),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () {
            // Si están cargando los datos, mostrar una tarjeta de balance predeterminada
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
            // Si hay un error, mostrar una tarjeta de balance predeterminada
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
        // Si están cargando los datos, mostrar una tarjeta de balance predeterminada
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
        // Si hay un error, mostrar una tarjeta de balance predeterminada
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
