// activity_chart.dart
// Gráfico de actividad financiera con manejo seguro de datos y formato de fechas

import 'package:finances/core/data/models/filter.dart';
import 'package:finances/core/data/providers/filter_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finances/core/data/providers/ingreso_provider.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'dart:math';

/// Modelo que representa una transacción financiera
/// - [fecha]: Fecha de la transacción
/// - [monto]: Valor monetario (positivo para ingresos, negativo para egresos)
/// - [esIngreso]: Bandera que indica si es un ingreso
class Transaction {
  final DateTime fecha;
  final double monto;
  final bool esIngreso;

  const Transaction({
    required this.fecha,
    required this.monto,
    required this.esIngreso,
  });
}

/// Clase para almacenar datos por período con ingresos y egresos separados
class PeriodData {
  final DateTime start;
  final double ingresos;
  final double egresos;

  PeriodData(
      {required this.start, required this.ingresos, required this.egresos});
}

/// Widget principal que muestra el gráfico de actividad financiera
class ActivityChart extends ConsumerWidget {
  const ActivityChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtener el filtro actual y los datos asincrónicos
    final filtro = ref.watch(filterProvider);
    final ingresosAsync = ref.watch(filteredIngresosProvider);
    final egresosAsync = ref.watch(filteredEgresosProvider);

    return ingresosAsync.when(
      data: (ingresos) => egresosAsync.when(
        data: (egresos) => _buildChartContent(ingresos, egresos, filtro),
        loading: _buildLoading,
        error: (err, _) => _buildError('Error en egresos: $err'),
      ),
      loading: _buildLoading,
      error: (err, _) => _buildError('Error en ingresos: $err'),
    );
  }

  /// Construye el contenido principal del gráfico
  Widget _buildChartContent(double ingresos, double egresos, Filter filtro) {
    final periodos = _generarPeriodos(filtro);
    final transacciones = _calcularTransacciones(ingresos, egresos, periodos);

    return Card(
      elevation: 0,
      color: Color.fromARGB(255, 206, 230, 248),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitulo(filtro),
            const SizedBox(height: 15),
            SizedBox(
              height: 250,
              child: BarChart(_crearDatosChart(transacciones, filtro)),
            ),
            const SizedBox(height: 10),
            _buildLeyenda(),
          ],
        ),
      ),
    );
  }

  /// Genera los períodos temporales según el filtro seleccionado
  List<DateTimeRange> _generarPeriodos(Filter filtro) {
    final rango = _calcularRango(filtro);
    final List<DateTimeRange> periodos = [];

    switch (filtro.type) {
      case FilterType.monthly:
        var current = DateTime(rango.start.year, rango.start.month);
        while (current.isBefore(rango.end)) {
          final next = current.add(const Duration(days: 30));
          periodos.add(DateTimeRange(
            start: current,
            end: next.isBefore(rango.end) ? next : rango.end,
          ));
          current = next.add(const Duration(days: 1));
        }
        break;
      case FilterType.quarterly:
        var current = DateTime(rango.start.year, rango.start.month);
        while (current.isBefore(rango.end)) {
          final next = DateTime(current.year, current.month + 3, current.day);
          periodos.add(DateTimeRange(
            start: current,
            end: next.isBefore(rango.end) ? next : rango.end,
          ));
          current = next.add(const Duration(days: 1));
        }
        break;
      case FilterType.annual:
        var current = DateTime(rango.start.year, 1, 1);
        while (current.isBefore(rango.end)) {
          final next = DateTime(current.year + 1, 1, 1);
          periodos.add(DateTimeRange(
            start: current,
            end: next.isBefore(rango.end) ? next : rango.end,
          ));
          current = next;
        }
        break;
      case FilterType.custom:
        final duration = rango.duration.inDays;
        final step = _calcularPasoPersonalizado(duration);

        var current = rango.start;
        while (current.isBefore(rango.end)) {
          final endDate = current.add(step);
          periodos.add(DateTimeRange(
            start: current,
            end: endDate.isBefore(rango.end) ? endDate : rango.end,
          ));
          current = endDate.add(const Duration(days: 1));
        }
        break;
    }
    return periodos;
  }

  /// Calcula el intervalo para el filtro personalizado
  Duration _calcularPasoPersonalizado(int duration) {
    if (duration > 180) return const Duration(days: 30);
    if (duration > 60) return const Duration(days: 7);
    return const Duration(days: 1);
  }

  /// Calcula las transacciones para cada período
  List<PeriodData> _calcularTransacciones(
      double totalIngresos, double totalEgresos, List<DateTimeRange> periodos) {
    if (periodos.isEmpty) return [];

    final totalDias = periodos.fold<double>(
        0, (sum, p) => sum + p.duration.inDays.toDouble());

    return periodos.map((periodo) {
      final factor = periodo.duration.inDays / totalDias;
      final ingresosPeriodo = totalIngresos * factor;
      final egresosPeriodo = totalEgresos * factor;
      return PeriodData(
        start: periodo.start,
        ingresos: ingresosPeriodo,
        egresos: egresosPeriodo,
      );
    }).toList();
  }

  /// Crea la configuración del gráfico con validación de datos
  BarChartData _crearDatosChart(List<PeriodData> periodosData, Filter filtro) {
    if (periodosData.isEmpty) return BarChartData(barGroups: []);

    return BarChartData(
      borderData: FlBorderData(
        show: false,
      ),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, _, rod, __) {
            final index = group.x.toInt();
            final pd = periodosData[index];
            final isIncome = group.barRods.indexOf(rod) == 0;
            return BarTooltipItem(
              '${rod.toY.toStringAsFixed(2)}\n${_formatoFecha(pd.start, filtro)}\n${isIncome ? 'Ingreso' : 'Egreso'}',
              const TextStyle(color: Colors.white, fontSize: 12),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _buildEtiquetaEjeX(value, periodosData, filtro),
                style: const TextStyle(fontSize: 10),
              ),
            ),
            reservedSize: 28,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(right: 10),
              /* child: Text(
                //formatCurrency(value),
                //style: const TextStyle(fontSize: 10),
              ),*/
            ),
            reservedSize: 40,
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      barGroups: periodosData.asMap().entries.map((entry) {
        final index = entry.key;
        final pd = entry.value;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: pd.ingresos,
              color: Colors.green[400]!,
              width: 15,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: pd.egresos,
              color: Colors.red[400]!,
              width: 15,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }).toList(),
      gridData: const FlGridData(show: false),
      alignment: BarChartAlignment.spaceAround,
      maxY: _calcularMaxY(periodosData),
    );
  }

  /// Calcula el valor máximo para el eje Y
  double _calcularMaxY(List<PeriodData> periodosData) {
    if (periodosData.isEmpty) return 0;
    final maxIngreso = periodosData.map((pd) => pd.ingresos).reduce(max);
    final maxEgreso = periodosData.map((pd) => pd.egresos).reduce(max);
    return max(maxIngreso, maxEgreso) * 1.15;
  }

  /// Formatea la fecha según el tipo de filtro
  String _formatoFecha(DateTime fecha, Filter filtro) {
    switch (filtro.type) {
      case FilterType.monthly:
        return DateFormat('dd/MM').format(fecha);
      case FilterType.quarterly:
        return DateFormat('MMM').format(fecha);
      case FilterType.annual:
        return 'T${((fecha.month - 1) ~/ 3) + 1}';
      case FilterType.custom:
        return DateFormat('dd/MM').format(fecha);
    }
  }

  /// Construye el título con rango de fechas
  Widget _buildTitulo(Filter filtro) {
    final rango = _calcularRango(filtro);
    return Text(
      '${DateFormat('dd/MM/yyyy').format(rango.start)} - '
      '${DateFormat('dd/MM/yyyy').format(rango.end)}',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  /// Construye etiquetas del eje X con validación
  String _buildEtiquetaEjeX(
      double value, List<PeriodData> periodosData, Filter filtro) {
    final index = value.toInt();
    if (index < 0 || index >= periodosData.length) return '';
    return _formatoFecha(periodosData[index].start, filtro);
  }

  /// Calcula el rango de fechas según el filtro
  DateTimeRange _calcularRango(Filter filtro) {
    final hoy = DateTime.now();
    switch (filtro.type) {
      case FilterType.monthly:
        return DateTimeRange(
          start: DateTime(hoy.year, hoy.month, 1),
          end: DateTime(hoy.year, hoy.month + 1, 0),
        );
      case FilterType.quarterly:
        final trimestre = ((hoy.month - 1) ~/ 3) + 1;
        return DateTimeRange(
          start: DateTime(hoy.year, (trimestre - 1) * 3 + 1, 1),
          end: DateTime(hoy.year, trimestre * 3 + 1, 0),
        );
      case FilterType.annual:
        return DateTimeRange(
          start: DateTime(hoy.year, 1, 1),
          end: DateTime(hoy.year, 12, 31),
        );
      case FilterType.custom:
        return DateTimeRange(
          start: filtro.startDate ?? hoy.subtract(const Duration(days: 30)),
          end: filtro.endDate ?? hoy,
        );
    }
  }

  /// Construye la leyenda del gráfico
  Widget _buildLeyenda() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildItemLeyenda(Colors.green, 'Ingresos'),
        const SizedBox(width: 20),
        _buildItemLeyenda(Colors.red, 'Egresos'),
      ],
    );
  }

  /// Componente individual de la leyenda
  Widget _buildItemLeyenda(Color color, String texto) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(texto, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  /// Estados de carga y error
  Widget _buildLoading() => const Center(child: CircularProgressIndicator());
  Widget _buildError(String mensaje) => Center(
        child: Text(mensaje,
            style: const TextStyle(color: Colors.red, fontSize: 14)),
      );
}
