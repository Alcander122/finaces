// activity_chart.dart
import 'package:finances/core/data/providers/filter_provider.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:finances/core/data/models/filter.dart';
import 'package:finances/core/data/providers/ingreso_provider.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';

class Transaction {
  final int dia;
  final double monto;

  Transaction({required this.dia, required this.monto});
}

class ActivityChart extends ConsumerWidget {
  const ActivityChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(filterProvider);
    final ingresosAsync = ref.watch(filteredIngresosProvider);
    final egresosAsync = ref.watch(filteredEgresosProvider);

    return ingresosAsync.when(
      data: (ingresos) {
        return egresosAsync.when(
          data: (egresos) {
            final transacciones = _prepararTransacciones(
              ingresos: ingresos,
              egresos: egresos,
              filtro: filtro,
            );

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _construirTituloGrafico(filtro: filtro),
                    const SizedBox(height: 15),
                    AspectRatio(
                      aspectRatio: 1.7,
                      child: LineChart(
                        _crearDatosLineChart(
                          transacciones: transacciones,
                          ingresos: ingresos,
                          egresos: egresos,
                          filtro: filtro,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error al cargar los egresos: $err'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error al cargar los ingresos: $err'),
    );
  }

  List<Transaction> _prepararTransacciones({
    required double ingresos,
    required double egresos,
    required Filter filtro,
  }) {
    List<Transaction> transacciones = [];
    DateTime fechaActual = filtro.startDate ?? DateTime.now().subtract(const Duration(days: 30));
    DateTime fechaFinal = filtro.endDate ?? DateTime.now();

    while (fechaActual.isBefore(fechaFinal)) {
      double montoIngreso = ingresos * (fechaActual.day / fechaFinal.day);
      double montoEgreso = egresos * (fechaActual.day / fechaFinal.day);

      transacciones.add(Transaction(dia: fechaActual.difference(filtro.startDate ?? DateTime.now()).inDays, monto: montoIngreso));
      transacciones.add(Transaction(dia: fechaActual.difference(filtro.startDate ?? DateTime.now()).inDays, monto: -montoEgreso));

      fechaActual = fechaActual.add(const Duration(days: 1));
    }

    return transacciones;
  }

  LineChartData _crearDatosLineChart({
    required List<Transaction> transacciones,
    required double ingresos,
    required double egresos,
    required Filter filtro,
  }) {
    final fechaInicio = filtro.startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final fechaFin = filtro.endDate ?? DateTime.now();

    final ingresosData = transacciones.where((t) => t.monto >= 0).toList();
    final egresosData = transacciones.where((t) => t.monto < 0).map((t) => Transaction(dia: t.dia, monto: -t.monto)).toList();

    double maximoY = 0;
    double maxX = 0;
    if (transacciones.isNotEmpty) {
      maximoY = ingresosData.isNotEmpty ? ingresosData.map((t) => t.monto).fold(0.0, (previous, current) => previous > current ? previous : current) * 1.1 : 0;
      maximoY = maximoY > (egresosData.isNotEmpty ? egresosData.map((t) => t.monto).fold(0.0, (previous, current) => previous > current ? previous : current) * 1.1 : 0) ? maximoY : egresosData.isNotEmpty ? egresosData.map((t) => t.monto).fold(0.0, (previous, current) => previous > current ? previous : current) * 1.1 : 0;
      maxX = transacciones.map((t) => t.dia).reduce((max, current) => current > max ? current : max).toDouble();
    }

    return LineChartData(
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: _crearTitulosFechas(fechaInicio, fechaFin, filtro, maxX),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: ingresosData.map((t) => FlSpot(t.dia.toDouble(), t.monto)).toList(),
          isCurved: true,
          barWidth: 3,
          color: Colors.green,
          belowBarData: BarAreaData(show: true, color: Colors.green.withAlpha(50)),
          dotData: FlDotData(show: true),
        ),
        LineChartBarData(
          spots: egresosData.map((t) => FlSpot(t.dia.toDouble(), t.monto)).toList(),
          isCurved: true,
          barWidth: 3,
          color: Colors.red,
          belowBarData: BarAreaData(show: true, color: Colors.red.withAlpha(50)),
          dotData: FlDotData(show: true),
        ),
      ],
      maxX: maxX,
      maxY: maximoY,
    );
  }

  AxisTitles _crearTitulosFechas(DateTime fechaInicio, DateTime fechaFin, Filter filter, double maxX) {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,
        getTitlesWidget: (valor, meta) {
          if (maxX == 0) return const Text('');
          final diaEnElRango = (fechaFin.difference(fechaInicio).inDays * valor / maxX).round();
          final fecha = fechaInicio.add(Duration(days: diaEnElRango));
          return Text(
            DateFormat.d().format(fecha),
            style: const TextStyle(fontSize: 10),
          );
        },
      ),
    );
  }

  Widget _construirTituloGrafico({required Filter filtro}) {
    String titulo;
    if (filtro.type == FilterType.annual) {
      titulo = 'Actividad Financiera ${DateTime.now().year}';
    } else if (filtro.type == FilterType.quarterly) {
      final trimestre = ((DateTime.now().month - 1) / 3).floor() + 1;
      titulo = 'Trimestre Q$trimestre ${DateTime.now().year}';
    } else {
      final startDate = filtro.startDate?.toLocal() ?? DateTime.now().subtract(const Duration(days: 30));
      final endDate = filtro.endDate?.toLocal() ?? DateTime.now();
      titulo = '${DateFormat.yMd().format(startDate)} - ${DateFormat.yMd().format(endDate)}';
    }
    return Text(
      titulo,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}