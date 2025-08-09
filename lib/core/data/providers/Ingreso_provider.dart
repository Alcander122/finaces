// lib/core/data/providers/ingreso_provider.dart
import 'package:finances/core/data/models/filter.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/filter_provider.dart';
import 'package:finances/core/data/services/ingresos_service.dart';
import 'package:finances/core/data/utils/date_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Proveedor singleton del servicio de ingresos
///
/// Este proveedor se usa para crear una única instancia del servicio de ingresos
/// que puede ser inyectada en otros proveedores y widgets
final ingresosServiceProvider = Provider<IngresosService>((ref) {
  return IngresosService();
});

/// Proveedor de ingresos filtrados (total)
///
/// Este proveedor ahora usa DateUtils para calcular rangos de fecha consistentes
/// con los filtros aplicados, asegurando que los valores sean correctos
///
/// Importancia:
/// - Antes, los valores se calculaban inconsistentemente para diferentes filtros
/// - Ahora, usa la misma lógica de cálculo para todos los tipos de filtro
final filteredIngresosProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);
  final filter = ref.watch(filterProvider);
  if (authState.user == null) return Stream.value(0.0);

  final service = ref.watch(ingresosServiceProvider);
  final now = DateTime.now();

  switch (filter.type) {
    case FilterType.monthly:
      final inicioMes = DateUtils.getStartOfMonth(now);
      final finMes = DateUtils.getEndOfMonth(now);
      return service.streamTotalIngresosInRange(
          authState.user!.uid, inicioMes, finMes);

    case FilterType.quarterly:
      final inicioTrimestre = DateUtils.getStartOfQuarter(now);
      final finTrimestre = DateUtils.getEndOfQuarter(now);
      return service.streamTotalIngresosInRange(
          authState.user!.uid, inicioTrimestre, finTrimestre);

    case FilterType.annual:
      final inicioAnio = DateUtils.getStartOfYear(now);
      final finAnio = DateUtils.getEndOfYear(now);
      return service.streamTotalIngresosInRange(
          authState.user!.uid, inicioAnio, finAnio);

    case FilterType.custom:
      if (filter.startDate != null && filter.endDate != null) {
        return service.streamTotalIngresosInRange(
          authState.user!.uid,
          filter.startDate!,
          filter.endDate!,
        );
      }
      return Stream.value(0.0);
  }
});

/// Proveedor de ingresos filtrados por rango de fechas (usado por la gráfica)
///
/// Este proveedor ya funcionaba correctamente y no requiere cambios
final ingresosFiltradosProvider =
    StreamProvider.autoDispose<List<Ingreso>>((ref) {
  final authState = ref.watch(authProvider);
  final filter = ref.watch(filterProvider);
  if (authState.user == null) return Stream.value([]);
  try {
    return ref.watch(ingresosServiceProvider).obtenerIngresosFiltrados(
          authState.user!.uid,
          filter.startDate,
          filter.endDate,
        );
  } catch (e) {
    return Stream.value([]); // Valor predeterminado en caso de error
  }
});

/// Proveedor para ingresos del mes actual con try-catch
///
/// IMPORTANTE: Este proveedor se mantiene para pantallas como el Home
/// que siempre necesitan mostrar el mes actual, sin importar el filtro global
final totalIngresosMesActualProvider =
    StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return Stream.value(0.0);
  final service = ref.watch(ingresosServiceProvider);
  try {
    return service.streamTotalIngresosMesActual(authState.user!.uid);
  } catch (e) {
    return Stream.value(0.0); // Valor predeterminado en caso de error
  }
});

/// Proveedor de ingresos por categoría (usado en CategorySummary)
final ingresosPorCategoriaProvider =
    Provider.family<AsyncValue<List<Ingreso>>, String>(
  (ref, categoria) => ref.watch(ingresosFiltradosProvider).whenData(
        (ingresos) => ingresos.where((i) => i.categoria == categoria).toList(),
      ),
);

/// Total de ingresos basado en filtro actual
final totalIngresosProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return Stream.value(0.0);
  try {
    final List<Ingreso> ingresos =
        ref.watch(ingresosFiltradosProvider).value ?? [];
    final double total =
        ref.watch(ingresosServiceProvider).calcularTotalIngresos(ingresos);
    return Stream.value(total);
  } catch (e) {
    return Stream.value(0.0); // Valor predeterminado en caso de error
  }
});
