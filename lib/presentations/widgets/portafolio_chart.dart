import 'package:flutter/material.dart';
import 'package:finances/core/data/models/portafolio_model.dart';
import 'package:fl_chart/fl_chart.dart';

class PortafolioChart extends StatelessWidget {
  final List<Portafolio> portafolios;

  const PortafolioChart({super.key, required this.portafolios});

  @override
  Widget build(BuildContext context) {
    if (portafolios.isEmpty) return const SizedBox.shrink();

    final total = portafolios.fold(0.0, (sum, item) => sum + item.valor);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AspectRatio(
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
    );
  }

  List<PieChartSectionData> _chartSections(double total) {
    return portafolios.map((portafolio) {
      final percentage = (portafolio.valor / total * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: _getColor(portafolio.categoria),
        value: portafolio.valor,
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

  Color _getColor(String categoria) {
    final colors = {
      'Criptomoneda': Colors.blue.shade700,
      'Acciones': Colors.green.shade700,
      'Bonos': Colors.orange.shade700,
      'Otros': Colors.purple.shade700,
    };
    return colors[categoria] ?? Colors.grey;
  }
}
