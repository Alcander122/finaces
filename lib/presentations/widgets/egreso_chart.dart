import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:finances/core/data/models/egreso_model.dart';

class EgresoChart extends StatelessWidget {
  final List<Egreso> egresos;

  const EgresoChart({super.key, required this.egresos});

  @override
  Widget build(BuildContext context) {
    // Calcular los totales por categoría
    Map<String, int> categoriaTotales = {};
    for (var egreso in egresos) {
      if (categoriaTotales.containsKey(egreso.categoria)) {
        categoriaTotales[egreso.categoria] =
            categoriaTotales[egreso.categoria]! + egreso.valor;
      } else {
        categoriaTotales[egreso.categoria] = egreso.valor;
      }
    }

    // Preparar los datos para el gráfico
    List<ChartData> datosGrafico = [];
    final colores = [
      const Color.fromRGBO(255, 99, 132, 1),
      const Color.fromRGBO(54, 162, 235, 1),
      const Color.fromRGBO(255, 206, 86, 1),
      const Color.fromRGBO(75, 192, 192, 1),
      const Color.fromRGBO(153, 102, 255, 1),
    ];

    for (var entry in categoriaTotales.entries) {
      datosGrafico.add(
        ChartData(
          categoria: entry.key,
          valor: entry.value.toDouble(),
          color: colores[datosGrafico.length % colores.length],
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: SfCircularChart(
        title: ChartTitle(text: 'Distribución de Egresos por Categoría'),
        legend: Legend(
          isVisible: true,
          position: LegendPosition.bottom,
        ),
        series: <CircularSeries>[
          PieSeries<ChartData, String>(
            dataSource: datosGrafico,
            xValueMapper: (ChartData data, _) => data.categoria,
            yValueMapper: (ChartData data, _) => data.valor,
            pointColorMapper: (ChartData data, _) => data.color,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          )
        ],
      ),
    );
  }
}

class ChartData {
  final String categoria;
  final double valor;
  final Color color;

  const ChartData({
    required this.categoria,
    required this.valor,
    required this.color,
  });
}
