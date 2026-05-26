import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/objetivo_ahorro.dart';
import 'package:finances/core/data/services/servicio_ahorro.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/errors/handlers/db_error_handler.dart';

/// Proveedor del servicio de ahorro
final ahorroServiceProvider = Provider<AhorroService>((ref) {
  return AhorroService();
});

/// Proveedor del stream de metas de ahorro.
/// Escucha los cambios en tiempo real desde Firestore.
final metasAhorroProvider = StreamProvider.autoDispose<List<ObjetivoAhorro>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    return Stream.value([]);
  }
  
  final ahorroService = ref.watch(ahorroServiceProvider);
  return ahorroService.obtenerMetas().handleError((error) {
    throw DbErrorHandler.handle(error);
  });
});

/// Controlador para mutaciones del módulo de ahorros (Metas)
class AhorroController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Estado inicial vacío
  }

  /// Crea una nueva meta de ahorro
  Future<void> crearMeta({
    required String nombre,
    required double montoObjetivo,
    required DateTime fechaObjetivo,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final service = ref.read(ahorroServiceProvider);
      await service.crearMeta(
        nombre: nombre,
        montoObjetivo: montoObjetivo,
        fechaObjetivo: fechaObjetivo,
        fechaCreacion: DateTime.now(),
      );
    });
    state = result;
    if (result.hasError) {
      throw DbErrorHandler.handle(result.error);
    }
  }

  /// Agrega una transacción (depósito o retiro) a una meta de ahorro
  Future<void> agregarTransaccion({
    required String metaId,
    required String tipo,
    required double monto,
    String? descripcion,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final service = ref.read(ahorroServiceProvider);
      await service.agregarTransaccion(
        metaId: metaId,
        tipo: tipo,
        monto: monto,
        descripcion: descripcion,
      );
    });
    state = result;
    if (result.hasError) {
      throw DbErrorHandler.handle(result.error);
    }
  }

  /// Elimina una meta de ahorro
  Future<void> eliminarMeta(String metaId) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final service = ref.read(ahorroServiceProvider);
      await service.eliminarMeta(metaId);
    });
    state = result;
    if (result.hasError) {
      throw DbErrorHandler.handle(result.error);
    }
  }
}

/// Proveedor global para el controlador de ahorros
final ahorroControllerProvider =
    AsyncNotifierProvider<AhorroController, void>(() {
  return AhorroController();
});

