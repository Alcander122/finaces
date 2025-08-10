// lib/core/data/providers/egreso_provider.dart
// ignore_for_file: depend_on_referenced_packages
import 'package:finances/core/data/providers/filter_provider.dart';
import 'package:finances/core/data/utils/date_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/core/data/services/egreso_service.dart';
import 'package:finances/core/data/models/filter.dart';
import 'package:flutter/foundation.dart';
import 'package:finances/core/data/providers/auth_provider.dart';

/// Proveedor singleton del servicio de egresos
///
/// Este proveedor se usa para crear una única instancia del servicio de egresos
/// que puede ser inyectada en otros proveedores y widgets
final egresoServiceProvider = Provider<EgresoService>((ref) {
  return EgresoService();
});

/// Proveedor de todos los egresos del usuario
///
/// Obtiene todos los egresos del usuario actual desde Firestore
/// y los devuelve como un Stream de lista de Egreso
final egresosProvider = StreamProvider.autoDispose<List<Egreso>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return Stream.value([]);
  final service = ref.watch(egresoServiceProvider);
  return service.obtenerEgresos(authState.user!.uid);
});

/// Proveedor del total de gastos filtrados
///
/// ✅ Ajustado para que el filtro "Trimestral" use el TRIMESTRE MÓVIL.
///    Esto significa que si hoy es agosto, mostrará mayo, junio y julio.
///    Si es enero, mostrará octubre, noviembre y diciembre del año anterior.
final filteredTotalGastosProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);
  final filter = ref.watch(filterProvider);
  if (authState.user == null) return Stream.value(0.0);

  final service = ref.watch(egresoServiceProvider);
  final now = DateTime.now();

  switch (filter.type) {
    case FilterType.monthly:
      // Mes actual
      final inicioMes = DateUtils.getStartOfMonth(now);
      final finMes = DateUtils.getEndOfMonth(now);
      return service.streamTotalGastosInRange(
        authState.user!.uid,
        inicioMes,
        finMes,
      );

    case FilterType.quarterly:
      // 🔹 Trimestre móvil: últimos 3 meses completos antes del mes actual
      final inicioTrimestre = DateUtils.getStartOfRollingQuarter(now);
      final finTrimestre = DateUtils.getEndOfRollingQuarter(now);
      return service.streamTotalGastosInRange(
        authState.user!.uid,
        inicioTrimestre,
        finTrimestre,
      );

    case FilterType.annual:
      // Año actual
      final inicioAnio = DateUtils.getStartOfYear(now);
      final finAnio = DateUtils.getEndOfYear(now);
      return service.streamTotalGastosInRange(
        authState.user!.uid,
        inicioAnio,
        finAnio,
      );

    case FilterType.custom:
      // Rango personalizado
      if (filter.startDate != null && filter.endDate != null) {
        return service.streamTotalGastosInRange(
          authState.user!.uid,
          filter.startDate!,
          filter.endDate!,
        );
      }
      return Stream.value(0.0);
  }
});

/// Proveedor específico para el total de gastos del mes actual
///
/// Este siempre muestra el mes actual, sin importar el filtro global
final totalEgresoMesActualProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    return Stream.value(0.0);
  }
  final service = ref.watch(egresoServiceProvider);
  return service
      .streamTotalGastosMesActual(authState.user!.uid)
      .handleError((error, stackTrace) {
    debugPrint('Error al obtener gastos: $error');
    return Stream.value(0.0);
  });
});

/// Proveedor de egresos filtrados por rango de fechas (usado por la gráfica)
///
/// Respeta el filtro aplicado (mensual, trimestral, anual, personalizado)
final egresosFiltradosProvider =
    StreamProvider.autoDispose<List<Egreso>>((ref) {
  final authState = ref.watch(authProvider);
  final filter = ref.watch(filterProvider);
  if (authState.user == null) return Stream.value([]);
  return ref.watch(egresoServiceProvider).obtenerEgresosFiltrados(
        authState.user!.uid,
        filter.startDate,
        filter.endDate,
      );
});

/// Proveedor de egresos por categoría (usado en CategorySummary)
///
/// Filtra los egresos por categoría respetando el rango de fechas filtrado
final egresosPorCategoriaProvider =
    Provider.family<AsyncValue<List<Egreso>>, String>(
  (ref, categoria) => ref.watch(egresosFiltradosProvider).whenData(
        (egresos) => egresos.where((e) => e.categoria == categoria).toList(),
      ),
);

/// Proveedor del total de egresos (usado en CategorySummary)
///
/// Calcula el total de egresos basándose en los egresos filtrados
final totalEgresosProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return Stream.value(0.0);
  return Stream.value(
    ref.watch(egresoServiceProvider).calcularTotalEgresos(
          ref.watch(egresosFiltradosProvider).value ?? [],
        ),
  );
});
