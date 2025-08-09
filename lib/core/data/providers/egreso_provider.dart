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
///
/// Importancia:
/// - Asegura que todos los componentes usen la misma instancia del servicio
/// - Facilita la inyección de dependencias y pruebas
final egresoServiceProvider = Provider<EgresoService>((ref) {
  return EgresoService();
});

/// Proveedor de todos los egresos del usuario
///
/// Este proveedor obtiene todos los egresos del usuario actual desde Firestore
/// y los devuelve como un Stream de lista de Egreso
///
/// Uso:
/// - Para mostrar todos los egresos en la pantalla de egresos
/// - Como base para otros proveedores que filtran los egresos
final egresosProvider = StreamProvider.autoDispose<List<Egreso>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return Stream.value([]);
  final service = ref.watch(egresoServiceProvider);
  return service.obtenerEgresos(authState.user!.uid);
});

/// Proveedor del total de gastos filtrados (CORREGIDO)
///
/// IMPORTANTE: Este proveedor reemplaza totalGastosProvider para que los valores
/// de gastos en las tarjetas resumen sean consistentes con los filtros aplicados
///
/// Antes, totalGastosProvider solo filtraba por estado 'Pendiente' sin considerar fechas,
/// lo que causaba inconsistencias cuando se cambiaban los filtros de fecha.
///
/// Solución:
/// - Calcula el total de gastos en el rango de fecha especificado por el filtro
/// - Usa DateUtils para asegurar consistencia en el cálculo de fechas
final filteredTotalGastosProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);
  final filter = ref.watch(filterProvider);
  if (authState.user == null) return Stream.value(0.0);

  final service = ref.watch(egresoServiceProvider);
  final now = DateTime.now();

  switch (filter.type) {
    case FilterType.monthly:
      // Calcular rango para el mes actual
      final inicioMes = DateUtils.getStartOfMonth(now);
      final finMes = DateUtils.getEndOfMonth(now);
      return service.streamTotalGastosInRange(
          authState.user!.uid, inicioMes, finMes);

    case FilterType.quarterly:
      // Calcular rango para el trimestre actual
      final inicioTrimestre = DateUtils.getStartOfQuarter(now);
      final finTrimestre = DateUtils.getEndOfQuarter(now);
      return service.streamTotalGastosInRange(
          authState.user!.uid, inicioTrimestre, finTrimestre);

    case FilterType.annual:
      // Calcular rango para el año actual
      final inicioAnio = DateUtils.getStartOfYear(now);
      final finAnio = DateUtils.getEndOfYear(now);
      return service.streamTotalGastosInRange(
          authState.user!.uid, inicioAnio, finAnio);

    case FilterType.custom:
      // Usar el rango personalizado seleccionado por el usuario
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
/// IMPORTANTE: Este proveedor se mantiene para compatibilidad con pantallas como el Home
///
/// Diferencia con filteredTotalGastosProvider:
/// - Este siempre muestra el mes actual, sin importar el filtro global
/// - filteredTotalGastosProvider respeta el filtro global (mensual, trimestral, etc.)
final totalEgresoMesActualProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    return Stream.value(0.0); // Si no hay usuario autenticado, devuelve 0
  }
  final service = ref.watch(egresoServiceProvider);
  return service
      .streamTotalGastosMesActual(authState.user!.uid)
      .handleError((error, stackTrace) {
    debugPrint('Error al obtener gastos: $error');
    return Stream.value(0.0); // En caso de error, devuelve 0
  });
});

/// Proveedor de egresos filtrados por rango de fechas (usado por la gráfica)
///
/// Este proveedor ya funcionaba correctamente y no requiere cambios
/// Es el que usa activity_chart.dart para obtener los datos para la gráfica
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
/// Este proveedor filtra los egresos por categoría usando los egresos filtrados
/// por fecha (egresosFiltradosProvider), asegurando que respete los filtros aplicados
final egresosPorCategoriaProvider =
    Provider.family<AsyncValue<List<Egreso>>, String>(
  (ref, categoria) => ref.watch(egresosFiltradosProvider).whenData(
        (egresos) => egresos.where((e) => e.categoria == categoria).toList(),
      ),
);

/// Proveedor del total de egresos (usado en CategorySummary)
///
/// Calcula el total de egresos basado en los egresos filtrados por fecha
final totalEgresosProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return Stream.value(0.0);
  return Stream.value(
    ref.watch(egresoServiceProvider).calcularTotalEgresos(
          ref.watch(egresosFiltradosProvider).value ?? [],
        ),
  );
});
