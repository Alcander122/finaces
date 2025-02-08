import 'package:finances/utils/category_color_generator.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finances/core/data/models/portafolio_model.dart';

class PortafolioChart extends StatelessWidget {
  final List<Portafolio> portafolios;

  const PortafolioChart({super.key, required this.portafolios});

  @override
  Widget build(BuildContext context) {
    if (portafolios.isEmpty) return const SizedBox.shrink();

    final categoriasUnicas = _obtenerCategoriasUnicas();
    final total = portafolios.fold(0.0, (sum, item) => sum + item.valor);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Distribución por Categoría',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1.2,
                child: PieChart(
                  PieChartData(
                    sections: _chartSections(total),
                    centerSpaceRadius: 40,
                    sectionsSpace: 0,
                    startDegreeOffset: -90,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildLeyenda(categoriasUnicas, context),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _chartSections(double total) {
    return portafolios.map((portafolio) {
      final percentage = (portafolio.valor / total * 100).toStringAsFixed(1);
      final color = CategoryColorGenerator.getColor(portafolio.categoria);

      return PieChartSectionData(
        color: color,
        value: portafolio.valor,
        title: '$percentage%',
        radius: 25,
        titleStyle: TextStyle(
          fontSize: 14,
          color: CategoryColorGenerator.getContrastTextColor(color),
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Widget _buildLeyenda(List<String> categorias, BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: categorias.map((categoria) {
        final color = CategoryColorGenerator.getColor(categoria);
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
              categoria,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<String> _obtenerCategoriasUnicas() {
    return portafolios.map((p) => p.categoria).toSet().toList();
  }
}
