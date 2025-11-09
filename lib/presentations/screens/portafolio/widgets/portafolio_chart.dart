import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/data/models/investment_model.dart';
import '../../../../core/data/models/portafolio_model.dart';
import '../../../../core/data/utils/ui_helpers.dart'; // Para formatCurrency.

// Gráfico de distribución de portafolios con mejoras de legibilidad.
class PortafolioChart extends StatefulWidget {
  final List<Investment> investments;
  final List<Portafolio> portfolios;

  const PortafolioChart(
      {super.key, required this.investments, required this.portfolios});

  @override
  State<PortafolioChart> createState() => _PortafolioChartState();
}

class _PortafolioChartState extends State<PortafolioChart> {
  int? touchedIndex; // Para tooltips al tocar.

  @override
  Widget build(BuildContext context) {
    if (widget.investments.isEmpty) return const SizedBox.shrink();

    final total =
        widget.investments.fold(0.0, (sum, item) => sum + item.invMensual);
    if (total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Distribución del Portafolio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              Text('Total: ${UIHelpers.formatCurrency(total)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 1.3,
                child: PieChart(
                  PieChartData(
                    sections: _chartSections(total),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = null;
                            return;
                          }
                          touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                        if (touchedIndex != null &&
                            touchedIndex! < widget.portfolios.length) {
                          final portafolio = widget.portfolios[touchedIndex!];
                          UIHelpers.showInfoSnackBar(
                              context: context,
                              message: 'Portafolio: ${portafolio.nombre}');
                        }
                      },
                    ),
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

  // Secciones del gráfico: Agrupa <5% en "".
  List<PieChartSectionData> _chartSections(double total) {
    final Map<String, double> aggregated = {};
    double othersValue = 0.0;

    for (final portfolio in widget.portfolios) {
      final value = widget.investments
          .where((inv) => inv.portafolioId == portfolio.id)
          .fold(0.0, (sum, inv) => sum + inv.invMensual);
      final percentage = value / total * 100;
      if (percentage < 5.0) {
        othersValue += value;
      } else {
        aggregated[portfolio.id] = value;
      }
    }

    final sections = <PieChartSectionData>[];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.grey
    ]; // Paleta fija.

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
        radius: 30,
        title: '$othersPercentage%',
        titleStyle: const TextStyle(
            fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
      ));
    }

    return sections;
  }

  // Leyenda desplazable.
  Widget _buildLeyenda() {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Wrap(
            spacing: 10,
            children: widget.portfolios.map((portfolio) {
              final color = _getColorForPortfolio(portfolio.id);
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 16,
                    height: 16,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(portfolio.nombre,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.bold)),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getColorForPortfolio(String id) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    return colors[
        widget.portfolios.indexWhere((p) => p.id == id) % colors.length];
  }
}
