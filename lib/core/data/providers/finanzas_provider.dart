// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/services/ingresos_service.dart';
import 'package:finances/core/data/providers/auth_provider.dart';

// Donde tengas tus providers
final totalIngresosProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return Stream.value(0.0);
  return IngresosService().streamTotalIngresos(authState.user!.uid);
});

final totalIngresosMesActualProvider =
    StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return Stream.value(0.0);
  return IngresosService().streamTotalIngresosMesActual(authState.user!.uid);
});
