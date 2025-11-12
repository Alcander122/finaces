import 'package:flutter/material.dart';
import 'package:finances/core/data/models/investment_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';

class InvestmentChart extends StatelessWidget {
  final List<Investment> investments;
  const InvestmentChart({super.key, required this.investments});

  @override
  Widget build(BuildContext context) {
    if (investments.isEmpty) return const SizedBox.shrink();

    final total = investments.fold(0.0, (sum, inv) => sum + inv.invMensual);
    if (total <= 0) return const SizedBox.shrink();

    return Container(
      color: Themes.light,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('Distribución de Inversiones',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blueGrey)),
              const SizedBox(height: 8),
              Text('Total: ${UIHelpers.formatCurrency(total)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 1.3,
                child: PieChart(PieChartData(
                  sections: _chartSections(total),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _chartSections(double total) {
    return investments.map((inv) {
      final percentage = (inv.invMensual / total * 100).toStringAsFixed(1);
      return PieChartSectionData(
        color: _generateColor(inv.activo),
        value: inv.invMensual,
        title: '$percentage%',
        radius: 30,
        titleStyle: const TextStyle(
            fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  Color _generateColor(String key) {
    final hash = key.hashCode;
    return Color.fromARGB(255, hash % 256, (hash * 2) % 256, (hash * 3) % 256);
  }
}
