import 'package:finances/core/data/models/filter.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/filter_provider.dart';
import 'package:finances/core/data/services/ingresos_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ingresosServiceProvider = Provider<IngresosService>((ref) {
  return IngresosService();
});

// Proveedor para ingresos filtrados
final filteredIngresosProvider = StreamProvider.autoDispose<double>((ref) {
  final authState =
      ref.watch(authProvider); // Observar el estado de autenticación
  final filter = ref.watch(filterProvider); // Observar el filtro actual
  if (authState.user == null) {
    return Stream.value(0.0); // Si no hay usuario, devolver 0.0
  }

  // Según el tipo de filtro, devolver el proveedor de ingresos correspondiente
  switch (filter.type) {
    case FilterType.monthly:
      // Devolver el total de ingresos del mes actual
      return IngresosService()
          .streamTotalIngresosMesActual(authState.user!.uid);
    case FilterType.quarterly:
    case FilterType.annual:
      // Devolver el total de ingresos (anuales o trimestrales)
      return IngresosService().streamTotalIngresos(authState.user!.uid);
    case FilterType.custom:
      // Devolver el total de ingresos en el rango de fechas seleccionado
      return IngresosService().streamTotalIngresosInRange(
        authState.user!.uid,
        filter.startDate!,
        filter.endDate!,
      );
  }
});

// Proveedor para ingresos del mes actual
final totalIngresosMesActualProvider =
    StreamProvider.autoDispose<double>((ref) {
  final authState =
      ref.watch(authProvider); // Observar el estado de autenticación
  if (authState.user == null) {
    return Stream.value(0.0); // Si no hay usuario, devolver 0.0
  }
  // Devolver el total de ingresos del mes actual
  return IngresosService().streamTotalIngresosMesActual(authState.user!.uid);
});

final ingresosFiltradosProvider =
    StreamProvider.autoDispose<List<Ingreso>>((ref) {
  final authState = ref.watch(authProvider);
  final filter = ref.watch(filterProvider);

  if (authState.user == null) return Stream.value([]);

  return ref.watch(ingresosServiceProvider).obtenerIngresosFiltrados(
        authState.user!.uid,
        filter.startDate,
        filter.endDate,
      );
});

final ingresosPorCategoriaProvider =
    Provider.family<AsyncValue<List<Ingreso>>, String>(
  (ref, categoria) => ref.watch(ingresosFiltradosProvider).whenData(
        (ingresos) => ingresos.where((i) => i.categoria == categoria).toList(),
      ),
);

final totalIngresosProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);

  if (authState.user == null) return Stream.value(0.0);

  return Stream.value(
    ref.watch(ingresosServiceProvider).calcularTotalIngresos(
          ref.watch(ingresosFiltradosProvider).value ?? [],
        ),
  );
});
