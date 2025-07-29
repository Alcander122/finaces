import 'package:finances/utils/utilities.dart';
import 'package:flutter/material.dart';
import 'package:finances/core/data/models/investment_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:intl/intl.dart';

class InvestmentChart extends StatelessWidget {
  final List<Investment> investments;

  const InvestmentChart({super.key, required this.investments});

  @override
  Widget build(BuildContext context) {
    if (investments.isEmpty) {
      return const SizedBox.shrink();
    }

    final total =
        investments.fold(0.0, (sum, investment) => sum + investment.invMensual);
    if (total == 0) {
      return const SizedBox.shrink();
    }

    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 2,
    );

    return Container(
      color: Themes.light,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Distribución de Inversiones',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${formatter.format(total)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 1.3,
                child: PieChart(
                  PieChartData(
                    sections: _chartSections(total),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    startDegreeOffset: -90,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _chartSections(double total) {
    return investments.map((investment) {
      final percentage =
          (investment.invMensual / total * 100).toStringAsFixed(1);
      return PieChartSectionData(
        color: _generateColor(investment.activo),
        value: investment.invMensual,
        title: '$percentage%',
        radius: 30,
        titleStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Color _generateColor(String key) {
    return Color.fromARGB(
      255,
      key.hashCode % 256,
      (key.hashCode * 2) % 256,
      (key.hashCode * 3) % 256,
    );
  }
}
