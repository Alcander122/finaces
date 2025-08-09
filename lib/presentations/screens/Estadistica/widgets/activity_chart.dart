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
import 'dart:math';

/// Clase que representa un periodo con datos de ingresos y egresos
///
/// Almacena los datos necesarios para mostrar en cada barra del gráfico:
/// - Fecha de inicio del periodo
/// - Total de ingresos en ese periodo
/// - Total de egresos en ese periodo
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

/// Widget para mostrar un gráfico de barras comparativo de ingresos y egresos
///
/// Este widget es responsivo y se adapta al filtro actual (mensual, trimestral, anual o personalizado)
/// Muestra una visualización clara de los movimientos financieros del usuario
class ActivityChart extends ConsumerWidget {
  const ActivityChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(filterProvider);
    final ingresosAsync = ref.watch(ingresosFiltradosProvider);
    final egresosAsync = ref.watch(egresosFiltradosProvider);

    // Esperamos a que ingresos y egresos estén listos antes de dibujar el gráfico
    return ingresosAsync.when(
      data: (ingresos) => egresosAsync.when(
        data: (egresos) => _buildChartContent(ingresos, egresos, filtro),
        loading: () => _buildLoading(),
        error: (err, stack) => _buildError('Error en egresos: $err'),
      ),
      loading: () => _buildLoading(),
      error: (err, stack) => _buildError('Error en ingresos: $err'),
    );
  }

  /// Construye el contenido del gráfico
  Widget _buildChartContent(
      List<Ingreso> ingresos, List<Egreso> egresos, Filter filtro) {
    final periodos = _generarPeriodos(filtro);

    // Calculamos ingresos y egresos por periodo usando las fechas REALES
    final transacciones =
        _calcularTransaccionesReal(ingresos, egresos, periodos);

    return Card(
      elevation: 0,
      color: const Color.fromARGB(255, 206, 230, 248),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitulo(filtro),
            const SizedBox(height: 15),
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(_crearDatosChart(transacciones, filtro)),
            ),
            const SizedBox(height: 10),
            _buildLeyenda(),
          ],
        ),
      ),
    );
  }

  /// Genera periodos según el filtro (mensual, trimestral, etc.)
  List<DateTimeRange> _generarPeriodos(Filter filtro) {
    final rango = _calcularRango(filtro);
    final List<DateTimeRange> periodos = [];

    switch (filtro.type) {
      case FilterType.monthly:
        var current = DateTime(rango.start.year, rango.start.month, 1);
        while (current.isBefore(rango.end.add(const Duration(days: 1)))) {
          periodos.add(DateTimeRange(start: current, end: current));
          current = current.add(const Duration(days: 1));
        }
        break;
      case FilterType.quarterly:
      case FilterType.annual:
        var current = DateTime(rango.start.year, rango.start.month, 1);
        while (current.isBefore(rango.end)) {
          final next = DateTime(current.year, current.month + 1, 1);
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

  /// 🔹 CORRECCIÓN IMPORTANTE:
  /// El método 'contains' no está disponible en todas las versiones de Flutter
  /// En su lugar, implementamos nuestra propia verificación según el tipo de filtro
  List<PeriodData> _calcularTransaccionesReal(List<Ingreso> ingresos,
      List<Egreso> egresos, List<DateTimeRange> periodos) {
    if (periodos.isEmpty) return [];

    return periodos
        .map((periodo) {
          double ingresosPeriodo = 0;
          double egresosPeriodo = 0;

          // --- INGRESOS ---
          for (var ingreso in ingresos) {
            final fechaIngreso = DateTime(
              ingreso.fechaIngreso.year,
              ingreso.fechaIngreso.month,
              ingreso.fechaIngreso.day,
            );

            // 🔴 CORRECCIÓN: En lugar de periodo.contains(fechaIngreso)
            // Usamos una verificación personalizada según el tipo de filtro
            if (_fechaPerteneceAlPeriodo(fechaIngreso, periodo)) {
              ingresosPeriodo += ingreso.valor;
            }
          }

          // --- EGRESOS ---
          for (var egreso in egresos) {
            final fechaEgreso = DateTime(
              egreso.fechaPago.year,
              egreso.fechaPago.month,
              egreso.fechaPago.day,
            );

            // 🔴 CORRECCIÓN: En lugar de periodo.contains(fechaEgreso)
            // Usamos una verificación personalizada según el tipo de filtro
            if (_fechaPerteneceAlPeriodo(fechaEgreso, periodo)) {
              egresosPeriodo += egreso.valor;
            }
          }

          return PeriodData(
            start: periodo.start,
            ingresos: ingresosPeriodo,
            egresos: egresosPeriodo,
          );
        })
        // Solo dejamos periodos que tengan datos
        .where((pd) => pd.ingresos > 0 || pd.egresos > 0)
        .toList();
  }

  /// Verifica si una fecha pertenece a un periodo específico
  ///
  /// Esta función reemplaza al método DateTimeRange.contains() que no está disponible
  /// en todas las versiones de Flutter.
  ///
  /// Funcionamiento:
  /// - Para filtro mensual: verifica si la fecha es igual al periodo (días específicos)
  /// - Para filtro anual: verifica si la fecha está en el mismo mes y año que el periodo
  bool _fechaPerteneceAlPeriodo(DateTime fecha, DateTimeRange periodo) {
    // Para el filtro mensual, cada periodo representa un día específico
    if (periodo.start.day != periodo.end.day) {
      // Si el periodo tiene más de un día (caso de filtro anual)
      return fecha.isAtSameMomentAs(periodo.start) ||
          (fecha.isAfter(periodo.start) && fecha.isBefore(periodo.end));
    } else {
      // Para el filtro mensual, cada periodo es un día específico
      return fecha.year == periodo.start.year &&
          fecha.month == periodo.start.month &&
          fecha.day == periodo.start.day;
    }
  }

  /// Configura el gráfico de barras
  BarChartData _crearDatosChart(List<PeriodData> periodosData, Filter filtro) {
    if (periodosData.isEmpty) return BarChartData(barGroups: []);

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
              const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
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
                textAlign: TextAlign.center,
              ),
            ),
            reservedSize: 28,
          ),
        ),
        // 🔹 AQUÍ SE ELIMINAN LOS VALORES DEL EJE IZQUIERDO
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false, // <--- OCULTAMOS LOS TÍTULOS DEL EJE IZQUIERDO
            reservedSize: 0, // <--- ELIMINAMOS EL ESPACIO RESERVADO
          ),
        ),
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
              color: Colors.green[400]!,
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: pd.egresos,
              color: Colors.red[400]!,
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

  double _calcularMaxY(List<PeriodData> periodosData) {
    if (periodosData.isEmpty) return 0;
    final maxIngreso = periodosData.map((pd) => pd.ingresos).reduce(max);
    final maxEgreso = periodosData.map((pd) => pd.egresos).reduce(max);
    return max(maxIngreso, maxEgreso) * 1.15;
  }

  /// 🔹 FORMATEO MEJORADO PARA NOMBRES DE MESES
  ///
  /// Ahora muestra los nombres de los meses en español y en mayúsculas
  /// Ejemplo: "ENE", "FEB", "MAR", etc. para el filtro anual
  String _formatoFecha(DateTime fecha, Filter filtro) {
    switch (filtro.type) {
      case FilterType.monthly:
        return DateFormat('dd').format(fecha);
      case FilterType.quarterly:
      case FilterType.annual:
        // SOLUCIÓN ALTERNATIVA: Nombres de meses hardcodeados
        // Esto no requiere initializeDateFormatting()
        final meses = [
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
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  Widget _buildTitulo(Filter filtro) {
    final rango = _calcularRango(filtro);
    return Text(
      '${DateFormat('dd/MM/yyyy').format(rango.start)} - ${DateFormat('dd/MM/yyyy').format(rango.end)}',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  String _buildEtiquetaEjeX(
      double value, List<PeriodData> periodosData, Filter filtro) {
    final index = value.toInt();
    if (index < 0 || index >= periodosData.length) return '';
    final pd = periodosData[index];
    return (pd.ingresos > 0 || pd.egresos > 0)
        ? _formatoFecha(pd.start, filtro)
        : '';
  }

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

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  Widget _buildError(String mensaje) => Center(
        child: Text(
          mensaje,
          style: const TextStyle(color: Colors.red, fontSize: 14),
        ),
      );
}
