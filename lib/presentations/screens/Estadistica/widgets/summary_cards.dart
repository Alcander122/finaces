import 'package:finances/core/data/models/filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/providers/ingreso_provider.dart';

class SummaryCards extends ConsumerWidget {
  final FilterType filter;
  final DateTimeRange? dateRange;

  const SummaryCards({
    super.key,
    required this.filter,
    this.dateRange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildIngresosCard(context, ref),
          _buildGastosCard(context, ref),
          _buildBalanceCard(context, ref),
        ],
      ),
    );
  }

  Widget _buildIngresosCard(BuildContext context, WidgetRef ref) {
    return ref.watch(filteredIngresosProvider).when(
          data: (data) {
            return _buildSummaryCard(
              context,
              title: 'Ingresos',
              value: '\$${data.toStringAsFixed(2)}',
              icon: Icons.arrow_upward,
              color: Colors.green,
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) => Text('Error: $error'),
        );
  }

  Widget _buildGastosCard(BuildContext context, WidgetRef ref) {
    return ref.watch(totalGastosProvider).when(
          data: (data) {
            return _buildSummaryCard(
              context,
              title: 'Gastos',
              value: '\$${data.toStringAsFixed(2)}',
              icon: Icons.arrow_downward,
              color: Colors.red,
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) => Text('Error: $error'),
        );
  }

  Widget _buildBalanceCard(BuildContext context, WidgetRef ref) {
    return ref.watch(filteredIngresosProvider).when(
          data: (ingresos) {
            return ref.watch(totalGastosProvider).when(
                  data: (gastos) {
                    double balance = ingresos - gastos;
                    Color balanceColor = balance >= 0 ? Colors.blue : Colors.red;

                    return _buildSummaryCard(
                      context,
                      title: 'Balance',
                      value: '\$${balance.toStringAsFixed(2)}',
                      icon: Icons.trending_up,
                      color: balanceColor,
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stackTrace) => Text('Error: $error'),
                );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) => Text('Error: $error'),
        );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
            colors: [color.withValues(alpha:0.2), color.withValues(alpha:0.1)],
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
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}