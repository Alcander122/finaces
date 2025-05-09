import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Widget para el gráfico de actividad financiera
class ActivityChart extends StatelessWidget {
  const ActivityChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: true),
              titlesData: FlTitlesData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    FlSpot(0, 3),
                    FlSpot(1, 5),
                    FlSpot(2, 7),
                    FlSpot(3, 5),
                    FlSpot(4, 8),
                    FlSpot(5, 10),
                    FlSpot(6, 12),
                  ],
                  isCurved: true,
                  barWidth: 3,
                  color: const Color(0xFF1976D2),
                  belowBarData: BarAreaData(show: true, color: const Color(0xFF1976D2).withOpacity(0.3)),
                ),
              ],
              maxX: 6,
              maxY: 12,
            ),
          ),
        ),
      ),
    );
  }
}