import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/ingreso_provider.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/db_error_handler.dart'; // Asegúrate de importar tu handler existente

/// Proveedor global del controlador de Ingresos
final ingresosControllerProvider =
    StateNotifierProvider<IngresosController, AsyncValue<void>>((ref) {
  return IngresosController(ref);
});

/// Controlador que gestiona las mutaciones (Crear, Editar, Eliminar) de Ingresos,
/// delegando la reactividad de la lista al StreamProvider existente, pero
/// controlando los estados de carga y error para el feedback visual en la UI.
class IngresosController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  // Almacenamiento temporal para el rollback (función deshacer)
  Ingreso? _ingresoEliminadoTemporal;

  IngresosController(this._ref) : super(const AsyncData(null));

  /// Agrega un nuevo ingreso de manera segura
  Future<void> agregarIngreso(Ingreso ingreso) async {
    final user = _ref.read(authProvider).user;
    if (user == null) {
      state = AsyncError(ErrorStrings.permissionDenied, StackTrace.current);
      return;
    }

    state = const AsyncLoading();
    try {
      final service = _ref.read(ingresosServiceProvider);
      await service.guardarIngreso(user.uid, ingreso);
      state = const AsyncData(null);
    } on FirebaseException catch (e) {
      // Pasamos el error por el handler centralizado
      final errorMessage = DbErrorHandler.handle(e);
      state = AsyncError(errorMessage, StackTrace.current);
    } catch (e) {
      state = AsyncError(ErrorStrings.saveIngresoFailed, StackTrace.current);
    }
  }

  /// Actualiza un ingreso existente
  Future<void> actualizarIngreso(Ingreso ingreso) async {
    final user = _ref.read(authProvider).user;
    if (user == null) {
      state = AsyncError(ErrorStrings.permissionDenied, StackTrace.current);
      return;
    }

    state = const AsyncLoading();
    try {
      final service = _ref.read(ingresosServiceProvider);
      await service.actualizarIngreso(user.uid, ingreso.id!, ingreso);
      state = const AsyncData(null);
    } on FirebaseException catch (e) {
      final errorMessage = DbErrorHandler.handle(e);
      state = AsyncError(errorMessage, StackTrace.current);
    } catch (e) {
      state = AsyncError(ErrorStrings.saveIngresoFailed, StackTrace.current);
    }
  }

  /// Elimina un ingreso y lo guarda en caché local por si el usuario desea deshacer
  Future<void> eliminarIngreso(Ingreso ingreso) async {
    final user = _ref.read(authProvider).user;
    if (user == null || ingreso.id == null) {
      state = AsyncError(ErrorStrings.permissionDenied, StackTrace.current);
      return;
    }

    // Guardamos el modelo antes de borrarlo por si hay rollback
    _ingresoEliminadoTemporal = ingreso;

    state = const AsyncLoading();
    try {
      final service = _ref.read(ingresosServiceProvider);
      await service.eliminarIngreso(user.uid, ingreso.id!);
      state = const AsyncData(null);
    } on FirebaseException catch (e) {
      final errorMessage = DbErrorHandler.handle(e);
      state = AsyncError(errorMessage, StackTrace.current);
    } catch (e) {
      state = AsyncError(ErrorStrings.deleteFailed, StackTrace.current);
    }
  }

  /// Función Rollback: Restaura el último ingreso eliminado
  Future<void> deshacerEliminacion() async {
    if (_ingresoEliminadoTemporal != null) {
      // Insertamos el registro con su ID original
      // (Dependiendo de si tu crear admite forzar el ID, o usando una función restaurar específica.
      // Por simplicidad reutilizaremos el agregarIngreso, que creará un nuevo doc si no existe forzado en _firestore)
      await agregarIngreso(_ingresoEliminadoTemporal!);
      _ingresoEliminadoTemporal = null; // Limpiamos caché
    }
  }
}
