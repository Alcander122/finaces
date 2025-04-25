import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:finances/core/data/models/ingreso.model.dart';

class IncomeChart extends StatelessWidget {
  final List<Ingreso> ingresos;

  const IncomeChart({super.key, required this.ingresos});

  @override
  Widget build(BuildContext context) {
    // Calcular los totales por categoría
    Map<String, int> categoriaTotales = {};
    for (var ingreso in ingresos) {
      if (categoriaTotales.containsKey(ingreso.categoria)) {
        categoriaTotales[ingreso.categoria] =
            categoriaTotales[ingreso.categoria]! + ingreso.valor;
      } else {
        categoriaTotales[ingreso.categoria] = ingreso.valor;
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
        title: ChartTitle(text: 'Distribución de Ingresos por Categoría'),
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
