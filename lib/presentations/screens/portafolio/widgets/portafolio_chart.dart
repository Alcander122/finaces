import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/data/models/investment_model.dart';
import '../../../../core/data/models/portafolio_model.dart';
import '../../../../utils/category_color_generator.dart';

class PortafolioChart extends StatelessWidget {
  final List<Investment> investments;
  final List<Portafolio> portfolios;

  const PortafolioChart({
    super.key,
    required this.investments,
    required this.portfolios,
  });

  @override
  Widget build(BuildContext context) {
    if (investments.isEmpty) return const SizedBox.shrink();

    final total = investments.fold(0.0, (sum, item) => sum + item.invMensual);
    if (total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Distribución del Portafolio',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
              _buildLeyenda(),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _chartSections(double total) {
    return portfolios.map((portfolio) {
      final portfolioInvestments =
          investments.where((inv) => inv.portafolioId == portfolio.id).toList();
      final value = portfolioInvestments.fold(
          0.0, (sum, investment) => sum + investment.invMensual);
      final percentage = (value / total * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: CategoryColorGenerator.getColor(portfolio.id),
        value: value,
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

  Widget _buildLeyenda() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: portfolios.map((portfolio) {
        final color = CategoryColorGenerator.getColor(portfolio.id);
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
            Text(
              portfolio.nombre,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
