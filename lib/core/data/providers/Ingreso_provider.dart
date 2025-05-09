import 'package:finances/core/data/models/filter.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/filter_provider.dart';
import 'package:finances/core/data/services/ingresos_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//Proveedor para ingresos filtrados
final filteredIngresosProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);
  final filter = ref.watch(filterProvider);

  if (authState.user == null) return Stream.value(0.0);

  switch (filter.type) {
    case FilterType.monthly:
      return IngresosService().streamTotalIngresosMesActual(authState.user!.uid);
    case FilterType.quarterly:
    case FilterType.annual:
      return IngresosService().streamTotalIngresos(authState.user!.uid);
    case FilterType.custom:
      return IngresosService().streamTotalIngresosInRange(
        authState.user!.uid,
        filter.startDate!,
        filter.endDate!,
      );
  }
});

//Proveedor para ingresos del mes actual
final totalIngresosMesActualProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return Stream.value(0.0);
  return IngresosService().streamTotalIngresosMesActual(authState.user!.uid);
});