import 'package:finances/utils/utilities.dart';
import 'package:flutter/material.dart';
import 'package:finances/core/data/models/investment_model.dart';
import 'package:fl_chart/fl_chart.dart';

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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Distribución de Inversiones',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 1.3,
                child: PieChart(
                  PieChartData(
                    sections: _chartSections(total),
                    centerSpaceRadius: 40,
                    sectionsSpace: 0,
                    startDegreeOffset: -90,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildLegend(),
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
        color: Color.fromARGB(
          255,
          investment.activo.hashCode % 256,
          (investment.activo.hashCode * 2) % 256,
          (investment.activo.hashCode * 3) % 256,
        ),
        value: investment.invMensual,
        title: '$percentage%',
        radius: 25,
        titleStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: investments.map((investment) {
        final color = Color.fromARGB(
          255,
          investment.activo.hashCode % 256,
          (investment.activo.hashCode * 2) % 256,
          (investment.activo.hashCode * 3) % 256,
        );
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.descripcion,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${Utilities.formatCurrency(investment.invMensual)} ${investment.moneda}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        );
      }).toList(),
    );
  }
}
