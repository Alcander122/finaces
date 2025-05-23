import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:intl/intl.dart';

class IncomeChart extends StatelessWidget {
  final List<Ingreso> ingresos;

  const IncomeChart({super.key, required this.ingresos});

  @override
  Widget build(BuildContext context) {
    // Sumar los valores por categoría
    final Map<String, int> categoriaTotales = {};
    for (var ingreso in ingresos) {
      categoriaTotales.update(
          ingreso.categoria, (value) => value + ingreso.valor,
          ifAbsent: () => ingreso.valor);
    }

    // Formateador de números con separador de miles
    final formatter = NumberFormat.decimalPattern('es_CO');

    // Colores para las categorías
    final colores = [
      const Color(0xFFFF6384), // Rojo
      const Color(0xFF36A2EB), // Azul
      const Color(0xFFFFCE56), // Amarillo
      const Color(0xFF4BC0C0), // Verde
      const Color(0xFF9966FF), // Morado
    ];

    // Construir la lista de datos para el gráfico
    final List<ChartData> datosGrafico = [];
    int colorIndex = 0;
    for (var entry in categoriaTotales.entries) {
      datosGrafico.add(
        ChartData(
          categoria: entry.key,
          valor: entry.value.toDouble(),
          color: colores[colorIndex % colores.length],
        ),
      );
      colorIndex++;
    }

    return SizedBox(
      height: 300,
      child: SfCircularChart(
        title: ChartTitle(
          text: 'Ingresos categorizados',
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        legend: Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
          textStyle: const TextStyle(fontSize: 12),
        ),
        series: <CircularSeries>[
          DoughnutSeries<ChartData, String>(
            dataSource: datosGrafico,
            xValueMapper: (ChartData data, _) => data.categoria,
            yValueMapper: (ChartData data, _) => data.valor,
            pointColorMapper: (ChartData data, _) => data.color,
            dataLabelMapper: (ChartData data, _) =>
                '${data.categoria}: ${formatter.format(data.valor)}',
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
              connectorLineSettings: ConnectorLineSettings(
                type: ConnectorType.curve,
                length: '10%',
              ),
              textStyle: TextStyle(fontSize: 11),
            ),
            radius: '80%',
            innerRadius: '60%',
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
