import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/data/models/investment_model.dart';
import '../../../../core/data/utils/ui_helpers.dart';
import '../../../../core/data/services/market_service.dart';

// Gráfico de inversiones con precios actualizados.
class InvestmentChart extends StatefulWidget {
  final List<Investment> investments;

  const InvestmentChart({super.key, required this.investments});

  @override
  State<InvestmentChart> createState() => _InvestmentChartState();
}

class _InvestmentChartState extends State<InvestmentChart> {
  final MarketService _marketService = MarketService();
  double totalUpdated = 0.0;

  @override
  void initState() {
    super.initState();
    _updateTotals();
  }

  Future<void> _updateTotals() async {
    double sum = 0.0;
    for (final investment in widget.investments) {
      double value = investment.invMensual;
      if (investment.activo == 'ETF SP&500') {
        final price =
            await _marketService.getCurrentPrice('SPY'); // Precio de S&P 500.
        if (price != null) value = price; // Actualiza si hay dato.
      }
      sum += value;
    }
    setState(() => totalUpdated = sum);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.investments.isEmpty) return const SizedBox.shrink();

    final total = totalUpdated > 0
        ? totalUpdated
        : widget.investments.fold(0.0, (sum, inv) => sum + inv.invMensual);

    return Container(
      color: Colors.white,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87)),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _chartSections(double total) {
    final Map<String, double> aggregated = {};
    double othersValue = 0.0;

    for (final investment in widget.investments) {
      final percentage = investment.invMensual / total * 100;
      if (percentage < 5.0) {
        othersValue += investment.invMensual;
      } else {
        aggregated[investment.activo] =
            (aggregated[investment.activo] ?? 0) + investment.invMensual;
      }
    }

    final sections = <PieChartSectionData>[];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.grey
    ];
    int index = 0;

    for (final entry in aggregated.entries) {
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      sections.add(PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value,
        title: '$percentage%',
        radius: 30,
        titleStyle: const TextStyle(
            fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
      ));
      index++;
    }

    if (othersValue > 0) {
      final othersPercentage = (othersValue / total * 100).toStringAsFixed(1);
      sections.add(PieChartSectionData(
        color: Colors.grey[300],
        value: othersValue,
        title: '\n$othersPercentage%',
        radius: 30,
        titleStyle: const TextStyle(
            fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
      ));
    }

    return sections;
  }
}
