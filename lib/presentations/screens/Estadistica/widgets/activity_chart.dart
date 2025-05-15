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
      data: (ingresos) => egresosAsync.when(
        data: (egresos) => _buildChartContent(ingresos, egresos, filtro),
        loading: () => _buildLoading(),
        error: (err, _) => _buildError('Egresos: $err'),
      ),
      loading: () => _buildLoading(),
      error: (err, _) => _buildError('Ingresos: $err'),
    );
  }

  Widget _buildChartContent(double ingresos, double egresos, Filter filtro) {
    final transacciones = _prepararTransacciones(
      ingresos: ingresos,
      egresos: egresos,
      filtro: filtro,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _construirTituloGrafico(filtro: filtro),
                const SizedBox(height: 15),
                SizedBox(
                  height: 250,
                  width: constraints.maxWidth,
                  child: LineChart(
                    _crearDatosLineChart(
                      transacciones: transacciones,
                      maxWidth: constraints.maxWidth,
                      filtro: filtro,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _calcularMaxY(List<Transaction> ingresos, List<Transaction> egresos) {
    final maxIngresos = ingresos.isNotEmpty 
        ? ingresos.map((t) => t.monto).reduce((a, b) => a > b ? a : b)
        : 0;
    
    final maxEgresos = egresos.isNotEmpty
        ? egresos.map((t) => t.monto).reduce((a, b) => a > b ? a : b)
        : 0;

    return (maxIngresos > maxEgresos ? maxIngresos : maxEgresos) * 1.1;
  }

  List<Transaction> _prepararTransacciones({
    required double ingresos,
    required double egresos,
    required Filter filtro,
  }) {
    List<Transaction> transacciones = [];
    DateTime fechaInicio = filtro.startDate ?? DateTime.now().subtract(const Duration(days: 30));
    DateTime fechaFin = filtro.endDate ?? DateTime.now();

    for (var fecha = fechaInicio; fecha.isBefore(fechaFin); fecha = fecha.add(const Duration(days: 1))) {
      final dia = fecha.difference(fechaInicio).inDays;
      final montoIngreso = (ingresos * (dia + 1) / fechaFin.difference(fechaInicio).inDays);
      final montoEgreso = (egresos * (dia + 1) / fechaFin.difference(fechaInicio).inDays);

      transacciones.add(Transaction(dia: dia, monto: montoIngreso));
      transacciones.add(Transaction(dia: dia, monto: -montoEgreso));
    }

    return transacciones;
  }

  LineChartData _crearDatosLineChart({
    required List<Transaction> transacciones,
    required double maxWidth,
    required Filter filtro,
  }) {
    final ingresosData = transacciones.where((t) => t.monto >= 0).toList();
    final egresosData = transacciones.where((t) => t.monto < 0)
      .map((t) => Transaction(dia: t.dia, monto: -t.monto)).toList();

    return LineChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: _crearTitulosFechas(filtro, maxWidth, transacciones),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        _crearLinea(ingresosData, Colors.green),
        _crearLinea(egresosData, Colors.red),
      ],
      minX: 0,
      maxX: transacciones.isNotEmpty ? transacciones.last.dia.toDouble() : 0,
      maxY: _calcularMaxY(ingresosData, egresosData),
    );
  }

  AxisTitles _crearTitulosFechas(Filter filtro, double maxWidth, List<Transaction> transacciones) {
    final fechaInicio = filtro.startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final totalDias = transacciones.isNotEmpty 
        ? transacciones.last.dia 
        : fechaInicio.difference(DateTime.now()).inDays.abs();

    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,
        interval: _calcularIntervalo(totalDias).toDouble(),
        getTitlesWidget: (value, _) => _buildFechaLabel(value, fechaInicio, maxWidth, totalDias),
      ),
    );
  }

  int _calcularIntervalo(int totalDias) {
    if (totalDias > 60) return 15;
    if (totalDias > 30) return 7;
    if (totalDias > 7) return 3;
    return 1;
  }

  Widget _buildFechaLabel(double value, DateTime fechaInicio, double maxWidth, int totalDias) {
    final fecha = fechaInicio.add(Duration(days: value.toInt()));
    return SizedBox(
      width: maxWidth / totalDias,
      child: Text(
        DateFormat.MMMd().format(fecha),
        style: TextStyle(fontSize: totalDias > 30 ? 8 : 10),
      ),
    );
  }

  LineChartBarData _crearLinea(List<Transaction> datos, Color color) {
    return LineChartBarData(
      spots: datos.map((t) => FlSpot(t.dia.toDouble(), t.monto)).toList(),
      isCurved: true,
      color: color,
      barWidth: 2,
      belowBarData: BarAreaData(show: true, color: color.withValues(alpha:0.1)),
      dotData: const FlDotData(show: false),
    );
  }

  Widget _construirTituloGrafico({required Filter filtro}) {
    final fechaInicio = filtro.startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final fechaFin = filtro.endDate ?? DateTime.now();
    return Text(
      '${DateFormat.yMd().format(fechaInicio)} - ${DateFormat.yMd().format(fechaFin)}',
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());
  Widget _buildError(String message) => Center(child: Text(message, style: const TextStyle(color: Colors.red)));
}