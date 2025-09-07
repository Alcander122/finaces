import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/bank_model.dart';
import 'package:finances/core/data/utils/banks_repository.dart';

final banksRepositoryProvider =
    Provider<BanksRepository>((ref) => BanksRepository());

// Proveedor para el estado de los bancos
final bancoNotifierProvider = StateNotifierProvider.family<BancoNotifier,
    AsyncValue<List<BancoModelo>>, String>((ref, userId) {
  return BancoNotifier(ref.watch(banksRepositoryProvider), userId);
});

class BancoNotifier extends StateNotifier<AsyncValue<List<BancoModelo>>> {
  final BanksRepository _repo;
  final String _userId;

  BancoNotifier(this._repo, this._userId) : super(const AsyncValue.loading()) {
    // Cargar bancos al inicializar
    _cargarBancos();
  }

  // Cargar bancos desde Firebase
  void _cargarBancos() async {
    state = await AsyncValue.guard(() async {
      try {
        final bancos = await _repo.getBanksByUserId(_userId).first;
        // Filtrar bancos con nombre válido
        final bancosValidos = bancos.where((b) => b.nombre.isNotEmpty).toList();
        return bancosValidos;
      } catch (e) {
        // Registrar el error para debugging
        print('Error al cargar bancos: $e');
        rethrow;
      }
    });
  }

  // Crear banco y actualizar estado con ID real
  Future<void> crearBanco(BancoModelo banco) async {
    state = await AsyncValue.guard(() async {
      try {
        final nuevoId = await _repo.crearBanco(banco);
        final bancoActualizado = banco.copyWith(id: nuevoId);
        final List<BancoModelo> currentState = state.valueOrNull ?? [];
        return [...currentState, bancoActualizado];
      } catch (e) {
        print('Error al crear banco: $e');
        rethrow;
      }
    });
  }

  // Actualizar banco existente
  Future<void> actualizarBanco(BancoModelo banco) async {
    state = await AsyncValue.guard(() async {
      try {
        await _repo.actualizarBanco(banco);
        final List<BancoModelo> currentState = state.valueOrNull ?? [];
        return currentState.map((b) => b.id == banco.id ? banco : b).toList();
      } catch (e) {
        print('Error al actualizar banco: $e');
        rethrow;
      }
    });
  }

  // Eliminar banco
  Future<void> eliminarBanco(String bancoId, String userId) async {
    state = await AsyncValue.guard(() async {
      try {
        await _repo.eliminarBanco(bancoId, userId);
        final List<BancoModelo> currentState = state.valueOrNull ?? [];
        return currentState.where((banco) => banco.id != bancoId).toList();
      } catch (e) {
        print('Error al eliminar banco: $e');
        rethrow;
      }
    });
  }
}
