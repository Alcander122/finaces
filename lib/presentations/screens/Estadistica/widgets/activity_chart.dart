// lib/presentations/widgets/activity_chart.dart
import 'package:finances/core/data/models/filter.dart';
import 'package:finances/core/data/providers/filter_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/core/data/providers/ingreso_provider.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'dart:math';
import 'package:finances/core/data/utils/date_utils.dart'
    as AppDateUtils; // Usamos prefijo para evitar conflictos
import 'package:finances/presentations/theme/theme.dart';

/// Clase que representa un periodo con ingresos y egresos
class PeriodData {
  final DateTime start;
  final double ingresos;
  final double egresos;

  PeriodData({
    required this.start,
    required this.ingresos,
    required this.egresos,
  });
}

/// Widget para mostrar un gráfico de barras comparativo
class ActivityChart extends ConsumerWidget {
  const ActivityChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(filterProvider);
    final ingresosAsync = ref.watch(ingresosFiltradosProvider);
    final egresosAsync = ref.watch(egresosFiltradosProvider);

    return ingresosAsync.when(
      data: (ingresos) => egresosAsync.when(
        data: (egresos) => _buildChartContent(context, ingresos, egresos, filtro),
        loading: _buildLoading,
        error: (err, _) => _buildError('Error en egresos: $err'),
      ),
      loading: _buildLoading,
      error: (err, _) => _buildError('Error en ingresos: $err'),
    );
  }

  Widget _buildChartContent(
      BuildContext context, List<Ingreso> ingresos, List<Egreso> egresos, Filter filtro) {
    final periodos = _generarPeriodos(filtro);
    final transacciones =
        _calcularTransaccionesReal(ingresos, egresos, periodos);

    return Card(
      elevation: 0,
      color: context.isDarkMode ? const Color(0xFF1E293B) : const Color.fromARGB(255, 206, 230, 248),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitulo(context, filtro),
            const SizedBox(height: 15),
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(_crearDatosChart(context, transacciones, filtro)),
            ),
            const SizedBox(height: 10),
            _buildLeyenda(context),
          ],
        ),
      ),
    );
  }

  /// Genera los periodos que se mostrarán en la gráfica
  ///
  /// 🔹 En el caso de "quarterly" (trimestral) ahora usa TRIMESTRE MÓVIL.
  List<DateTimeRange> _generarPeriodos(Filter filtro) {
    final rango = _calcularRango(filtro);
    final List<DateTimeRange> periodos = [];

    switch (filtro.type) {
      case FilterType.monthly:
        // Cada barra representa un día del mes
        var current = DateTime(rango.start.year, rango.start.month, 1);
        while (current.isBefore(rango.end.add(const Duration(days: 1)))) {
          periodos.add(DateTimeRange(start: current, end: current));
          current = current.add(const Duration(days: 1));
        }
        break;

      case FilterType.quarterly:
      case FilterType.annual:
        // Cada barra representa un mes dentro del rango
        var current = rango.start;
        while (current.isBefore(rango.end)) {
          final lastDayOfMonth =
              DateTime(current.year, current.month + 1, 0, 23, 59, 59, 999);
          final endDate =
              lastDayOfMonth.isBefore(rango.end) ? lastDayOfMonth : rango.end;
          periodos.add(DateTimeRange(start: current, end: endDate));
          current = DateTime(current.year, current.month + 1, 1);
        }
        break;

      case FilterType.custom:
        // Agrupación dinámica según la duración total
        final duration = rango.duration.inDays;
        final step = _calcularPasoPersonalizado(duration);
        var current = rango.start;
        while (current.isBefore(rango.end.add(const Duration(days: 1)))) {
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

  Duration _calcularPasoPersonalizado(int duration) {
    if (duration > 180) return const Duration(days: 30);
    if (duration > 60) return const Duration(days: 7);
    return const Duration(days: 1);
  }

  List<PeriodData> _calcularTransaccionesReal(List<Ingreso> ingresos,
      List<Egreso> egresos, List<DateTimeRange> periodos) {
    return periodos
        .map((periodo) {
          double ingresosPeriodo = 0;
          double egresosPeriodo = 0;

          for (var ingreso in ingresos) {
            if (_fechaPerteneceAlPeriodo(ingreso.fechaIngreso, periodo)) {
              ingresosPeriodo += ingreso.valor;
            }
          }
          for (var egreso in egresos) {
            if (_fechaPerteneceAlPeriodo(egreso.fechaPago, periodo)) {
              egresosPeriodo += egreso.valor;
            }
          }

          return PeriodData(
            start: periodo.start,
            ingresos: ingresosPeriodo,
            egresos: egresosPeriodo,
          );
        })
        .where((pd) => pd.ingresos > 0 || pd.egresos > 0)
        .toList();
  }

  bool _fechaPerteneceAlPeriodo(DateTime fecha, DateTimeRange periodo) {
    final fechaNormalizada =
        DateTime(fecha.year, fecha.month, fecha.day); // Sin hora
    return !fechaNormalizada.isBefore(periodo.start) &&
        !fechaNormalizada.isAfter(periodo.end);
  }

  BarChartData _crearDatosChart(BuildContext context, List<PeriodData> periodosData, Filter filtro) {
    final isDark = context.isDarkMode;
    return BarChartData(
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (barGroup, groupIndex, rod, rodIndex) {
            final pd = periodosData[groupIndex];
            final isIncome = rodIndex == 0;
            return BarTooltipItem(
              '${formatCurrency(rod.toY)}\n${_formatoFecha(pd.start, filtro)}\n${isIncome ? 'Ingreso' : 'Egreso'}',
              const TextStyle(color: Colors.white, fontSize: 12),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, _) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _buildEtiquetaEjeX(value, periodosData, filtro),
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        ),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      barGroups: periodosData.asMap().entries.map((entry) {
        final pd = entry.value;
        return BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: pd.ingresos,
              color: Colors.green[400],
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: pd.egresos,
              color: Colors.red[400],
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }).toList(),
      gridData: const FlGridData(show: false),
      alignment: BarChartAlignment.center,
      maxY: _calcularMaxY(periodosData),
    );
  }

  double _calcularMaxY(List<PeriodData> data) {
    if (data.isEmpty) return 0;
    return max(
          data.map((e) => e.ingresos).reduce(max),
          data.map((e) => e.egresos).reduce(max),
        ) *
        1.15;
  }

  String _formatoFecha(DateTime fecha, Filter filtro) {
    switch (filtro.type) {
      case FilterType.monthly:
        return DateFormat('dd').format(fecha);
      case FilterType.quarterly:
      case FilterType.annual:
        const meses = [
          'ENE',
          'FEB',
          'MAR',
          'ABR',
          'MAY',
          'JUN',
          'JUL',
          'AGO',
          'SEP',
          'OCT',
          'NOV',
          'DIC'
        ];
        return meses[fecha.month - 1];
      case FilterType.custom:
        return DateFormat('dd/MM').format(fecha);
    }
  }

  String formatCurrency(double value) {
    return UIHelpers.formatCurrency(value);
  }

  Widget _buildTitulo(BuildContext context, Filter filtro) {
    final rango = _calcularRango(filtro);
    return Text(
      '${DateFormat('dd/MM/yyyy').format(rango.start)} - ${DateFormat('dd/MM/yyyy').format(rango.end)}',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: context.isDarkMode ? Colors.white70 : Colors.black87,
      ),
    );
  }

  String _buildEtiquetaEjeX(
      double value, List<PeriodData> periodosData, Filter filtro) {
    final index = value.toInt();
    if (index < 0 || index >= periodosData.length) return '';
    return _formatoFecha(periodosData[index].start, filtro);
  }

  /// 🔹 Ahora, para trimestral, devuelve trimestre móvil
  DateTimeRange _calcularRango(Filter filtro) {
    final hoy = DateTime.now();
    switch (filtro.type) {
      case FilterType.monthly:
        return DateTimeRange(
          start: AppDateUtils.DateUtils.getStartOfMonth(hoy),
          end: AppDateUtils.DateUtils.getEndOfMonth(hoy),
        );
      case FilterType.quarterly:
        return DateTimeRange(
          start: AppDateUtils.DateUtils.getStartOfRollingQuarter(hoy),
          end: AppDateUtils.DateUtils.getEndOfRollingQuarter(hoy),
        );
      case FilterType.annual:
        return DateTimeRange(
          start: AppDateUtils.DateUtils.getStartOfYear(hoy),
          end: AppDateUtils.DateUtils.getEndOfYear(hoy),
        );
      case FilterType.custom:
        return DateTimeRange(
          start: filtro.startDate ?? hoy.subtract(const Duration(days: 30)),
          end: filtro.endDate ?? hoy,
        );
    }
  }

  Widget _buildLeyenda(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildItemLeyenda(context, Colors.green, 'Ingresos'),
        const SizedBox(width: 20),
        _buildItemLeyenda(context, Colors.red, 'Egresos'),
      ],
    );
  }

  Widget _buildItemLeyenda(BuildContext context, Color color, String texto) {
    final isDark = context.isDarkMode;
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 5),
        Text(texto, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
      ],
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  Widget _buildError(String mensaje) =>
      Center(child: Text(mensaje, style: const TextStyle(color: Colors.red)));
}
