// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:finances/core/data/providers/filter_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/core/data/services/egreso_service.dart';
import 'package:finances/core/data/models/filter.dart';
import 'package:flutter/foundation.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/errors/handlers/db_error_handler.dart';

final egresoServiceProvider = Provider<EgresoService>((ref) {
  return EgresoService();
});

/// Controller moderno para manejar CRUD de forma centralizada y asíncrona
/// Esto permite a la UI interactuar con Firebase sin ensuciarse con try/catches.
class EgresosController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Inicialización del estado
  }

  Future<void> addEgreso(Egreso egreso) async {
    final user = ref.read(authProvider).user;
    if (user == null) throw Exception("Usuario no autenticado");

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(egresoServiceProvider).addEgreso(user.uid, egreso);
    });

    // Si state.hasError, la UI lo atrapará al escuchar el controller.
    if (state.hasError) {
      // El error ya viene limpio desde EgresoService > DbErrorHandler
      throw state.error!;
    }
  }

  Future<void> updateEgreso(Egreso egreso) async {
    final user = ref.read(authProvider).user;
    if (user == null) throw Exception("Usuario no autenticado");

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(egresoServiceProvider).actualizarEgreso(user.uid, egreso);
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> deleteEgreso(String id) async {
    final user = ref.read(authProvider).user;
    if (user == null) throw Exception("Usuario no autenticado");

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(egresoServiceProvider).eliminarEgreso(user.uid, id);
    });
    if (state.hasError) throw state.error!;
  }
}

// Provider del Controller
final egresosControllerProvider =
    AsyncNotifierProvider<EgresosController, void>(() {
  return EgresosController();
});

// STREAMS DE LECTURA (UI)
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

  return service
      .streamTotalGastosMesActual(authState.user!.uid)
      .handleError((error, stackTrace) {
    debugPrint('Error al obtener gastos: $error');
    throw DbErrorHandler.handle(error);
  });
});

final filteredEgresosProvider = StreamProvider.autoDispose<double>((ref) {
  // Observa el provider que ya trae la lista filtrada de Firebase
  final listAsync = ref.watch(egresosFiltradosProvider);
  
  return listAsync.when(
    data: (egresos) {
      final total = egresos.fold(0.0, (sum, item) => sum + item.valor.toDouble());
      return Stream.value(total);
    },
    loading: () => const Stream.empty(),
    error: (e, s) => Stream.error(e, s),
  );
});

final egresosFiltradosProvider =
    StreamProvider.autoDispose<List<Egreso>>((ref) {
  final authState = ref.watch(authProvider);
  final filter = ref.watch(filterProvider);

  if (authState.user == null) return Stream.value([]);

  // Usamos un try/catch o el manejador de errores de nuestro Stream
  return ref.watch(egresoServiceProvider).obtenerEgresosFiltrados(
        authState.user!.uid,
        filter.startDate,
        filter.endDate,
      );
});

final egresosPorCategoriaProvider =
    Provider.family<AsyncValue<List<Egreso>>, String>(
  (ref, categoria) => ref.watch(egresosFiltradosProvider).whenData(
        (egresos) => egresos.where((e) => e.categoria == categoria).toList(),
      ),
);

final totalEgresosProvider = StreamProvider.autoDispose<double>((ref) {
  final authState = ref.watch(authProvider);

  if (authState.user == null) return Stream.value(0.0);

  return Stream.value(
    ref.watch(egresoServiceProvider).calcularTotalEgresos(
          ref.watch(egresosFiltradosProvider).value ?? [],
        ),
  );
});
