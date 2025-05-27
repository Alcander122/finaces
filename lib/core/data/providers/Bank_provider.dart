import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/bank_model.dart';
import 'package:finances/core/data/utils/banks_repository.dart';

final banksRepositoryProvider = Provider<BanksRepository>((ref) => BanksRepository());

// Proveedor para el estado de los bancos
final bancoNotifierProvider = StateNotifierProvider.family<BancoNotifier, AsyncValue<List<BancoModelo>>, String>((ref, userId) {
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
      return await _repo.getBanksByUserId(_userId).first;
    });
  }

  // Crear banco y actualizar estado con ID real
  Future<void> crearBanco(BancoModelo banco) async {
    state = await AsyncValue.guard(() async {
      final nuevoId = await _repo.crearBanco(banco);
      final bancoActualizado = banco.copyWith(id: nuevoId);
      final List<BancoModelo> currentState = state.value ?? [];
      return [...currentState, bancoActualizado];
    });
  }

  // Actualizar banco existente
  Future<void> actualizarBanco(BancoModelo banco) async {
    state = await AsyncValue.guard(() async {
      await _repo.actualizarBanco(banco);
      final List<BancoModelo> currentState = state.value ?? [];
      return currentState.map((b) => b.id == banco.id ? banco : b).toList();
    });
  }

  // Eliminar banco
  Future<void> eliminarBanco(String bancoId, String userId) async {
    state = await AsyncValue.guard(() async {
      await _repo.eliminarBanco(bancoId, userId);
      final List<BancoModelo> currentState = state.value ?? [];
      return currentState.where((banco) => banco.id != bancoId).toList();
    });
  }
}