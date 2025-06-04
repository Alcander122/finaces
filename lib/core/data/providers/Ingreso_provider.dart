import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:finances/core/data/models/filter.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/filter_provider.dart';
import 'package:finances/core/data/services/ingresos_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Proveedor singleton del servicio de ingresos
final ingresosServiceProvider = Provider<IngresosService>((ref) {
  return IngresosService();
});

// Proveedor de ingresos filtrados (total)
final filteredIngresosProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);
  final filter = ref.watch(filterProvider);
  if (authState.user == null) return Stream.value(0.0);

  try {
    switch (filter.type) {
      case FilterType.monthly:
        return ref
            .watch(ingresosServiceProvider)
            .streamTotalIngresosMesActual(authState.user!.uid);
      case FilterType.quarterly:
      case FilterType.annual:
        return ref
            .watch(ingresosServiceProvider)
            .streamTotalIngresos(authState.user!.uid);
      case FilterType.custom:
        return ref.watch(ingresosServiceProvider).streamTotalIngresosInRange(
              authState.user!.uid,
              filter.startDate!,
              filter.endDate!,
            );
    }
  } catch (e) {
    return Stream.value(0.0);
  }
});

// Proveedor para ingresos del mes actual con try-catch
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

// Proveedor de ingresos filtrados por rango de fechas
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

// Proveedor de ingresos por categoría
final ingresosPorCategoriaProvider =
    Provider.family<AsyncValue<List<Ingreso>>, String>(
  (ref, categoria) => ref.watch(ingresosFiltradosProvider).whenData(
        (ingresos) => ingresos.where((i) => i.categoria == categoria).toList(),
      ),
);

// Total de ingresos basado en filtro actual con try-catch
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
