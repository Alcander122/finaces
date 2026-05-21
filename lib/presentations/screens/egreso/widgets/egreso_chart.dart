import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/utils/category_color_generator.dart';

class EgresoChart extends StatelessWidget {
  final List<Egreso> egresos;

  const EgresoChart({super.key, required this.egresos});

  @override
  Widget build(BuildContext context) {
    if (egresos.isEmpty) return const SizedBox.shrink();

    // Calcular los totales por categoría
    Map<String, double> categoriaTotales = {};
    double totalEgresos = 0;

    for (var egreso in egresos) {
      final double valor = egreso.valor.toDouble();
      if (categoriaTotales.containsKey(egreso.categoria)) {
        categoriaTotales[egreso.categoria] = categoriaTotales[egreso.categoria]! + valor;
      } else {
        categoriaTotales[egreso.categoria] = valor;
      }
      totalEgresos += valor;
    }

    // Preparar los datos para el gráfico
    List<ChartData> datosGrafico = [];

    for (var entry in categoriaTotales.entries) {
      datosGrafico.add(
        ChartData(
          categoria: entry.key,
          valor: entry.value,
          color: CategoryColorGenerator.getColor(entry.key),
        ),
      );
    }

    // Ordenar de mayor a menor para mejor visualización
    datosGrafico.sort((a, b) => b.valor.compareTo(a.valor));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Themes.primary,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 320,
          child: SfCircularChart(
            onTooltipRender: (TooltipArgs args) {
              final data = datosGrafico[args.pointIndex!.toInt()];
              args.text = '${data.categoria} : ${UIHelpers.formatCurrency(data.valor)}';
            },
            annotations: <CircularChartAnnotation>[
              CircularChartAnnotation(
                widget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total Gastos', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      UIHelpers.formatCurrency(totalEgresos),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            ],
            legend: Legend(
              isVisible: true,
              position: LegendPosition.bottom,
              overflowMode: LegendItemOverflowMode.wrap,
              textStyle: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            series: <CircularSeries>[
              DoughnutSeries<ChartData, String>(
                dataSource: datosGrafico,
                xValueMapper: (ChartData data, _) => data.categoria,
                yValueMapper: (ChartData data, _) => data.valor,
                dataLabelMapper: (ChartData data, _) => UIHelpers.formatCurrency(data.valor),
                pointColorMapper: (ChartData data, _) => data.color,
                innerRadius: '65%',
                radius: '100%',
                explode: true,
                explodeGesture: ActivationMode.singleTap,
                explodeOffset: '5%',
                enableTooltip: true,
                dataLabelSettings: const DataLabelSettings(
                  isVisible: false, // Hide labels inside the donut for a cleaner look, rely on tooltip & legend
                ),
              )
            ],
          ),
        ),
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
