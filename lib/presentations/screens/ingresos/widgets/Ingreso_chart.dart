import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:intl/intl.dart';

class IncomeChart extends StatelessWidget {
  final List<Ingreso> ingresos;

  const IncomeChart({super.key, required this.ingresos});

  @override
  Widget build(BuildContext context) {
    // Calcular los totales por categoría
    final Map<String, int> categoriaTotales = {};
    for (var ingreso in ingresos) {
      categoriaTotales.update(
        ingreso.categoria,
        (value) => value + ingreso.valor,
        ifAbsent: () => ingreso.valor,
      );
    }

    // Colores para las categorías
    final colores = [
      const Color.fromRGBO(255, 99, 132, 1), // Rojo
      const Color.fromRGBO(54, 162, 235, 1), // Azul
      const Color.fromRGBO(255, 206, 86, 1), // Amarillo
      const Color.fromRGBO(75, 192, 192, 1), // Verde
      const Color.fromRGBO(153, 102, 255, 1), // Morado
    ];

    // Construir los datos para el gráfico
    final List<ChartData> datosGrafico = [];
    for (var entry in categoriaTotales.entries) {
      datosGrafico.add(
        ChartData(
          categoria: entry.key,
          valor: entry.value.toDouble(),
          color: colores[datosGrafico.length % colores.length],
        ),
      );
    }

    // Formato de moneda
    final formatoMoneda = NumberFormat('#,##0', 'es_CO');

    return SizedBox(
      height: 300,
      child: SfCircularChart(
        title: ChartTitle(
          text: 'Ingresos Categorizados',
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
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
            dataLabelMapper: (ChartData data, _) =>
                '\$ ${formatoMoneda.format(data.valor)}',
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
