// ignore_for_file: depend_on_referenced_packages

import 'package:finances/core/data/providers/filter_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/core/data/services/egreso_service.dart';
import 'package:finances/core/data/models/filter.dart';
import 'package:finances/core/data/providers/auth_provider.dart';

final egresoServiceProvider = Provider<EgresoService>((ref) {
  return EgresoService();
});

final egresosProvider = StreamProvider.autoDispose<List<Egreso>>((ref) {
  final authState = ref.watch(authProvider);

  if (authState.user == null) return Stream.value([]);

  final service = ref.watch(egresoServiceProvider);
  return service.obtenerEgresos(authState.user!.uid);
});

final totalGastosProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);

  if (authState.user == null) return Stream.value(0.0);

  final service = ref.watch(egresoServiceProvider);
  return service.streamTotalGastos(authState.user!.uid);
});

final totalEgresoMesActualProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);

  if (authState.user == null) return Stream.value(0.0);

  final service = ref.watch(egresoServiceProvider);
  return service.streamTotalIngresosMesActual(authState.user!.uid);
});

final filteredEgresosProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);
  final filter = ref.watch(filterProvider);

  if (authState.user == null) return Stream.value(0.0);

  switch (filter.type) {
    case FilterType.monthly:
      return EgresoService().streamTotalGastosMesActual(authState.user!.uid);
    case FilterType.quarterly:
    case FilterType.annual:
      return EgresoService().streamTotalGastos(authState.user!.uid);
    case FilterType.custom:
      return EgresoService().streamTotalGastosInRange(
        authState.user!.uid,
        filter.startDate!,
        filter.endDate!,
      );
  }
});
final egresosFiltradosProvider = StreamProvider.autoDispose<List<Egreso>>((ref) {
  final authState = ref.watch(authProvider);
  final filter = ref.watch(filterProvider);

  if (authState.user == null) return Stream.value([]);

  return ref.watch(egresoServiceProvider).obtenerEgresosFiltrados(
        authState.user!.uid,
        filter.startDate,
        filter.endDate,
      );
});

// En Egreso_provider.dart
final egresosPorCategoriaProvider = Provider.family<AsyncValue<List<Egreso>>, String>(
  (ref, categoria) => ref.watch(egresosFiltradosProvider).whenData(
    (egresos) => egresos.where((e) => e.categoria == categoria).toList(),
  ),
);

final totalEgresosProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);
  final filter = ref.watch(filterProvider);

  if (authState.user == null) return Stream.value(0.0);

  return Stream.value(
    ref.watch(egresoServiceProvider).calcularTotalEgresos(
      ref.watch(egresosFiltradosProvider).value ?? [],
    ),
  );
});
