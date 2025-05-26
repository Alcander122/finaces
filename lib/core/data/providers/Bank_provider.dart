import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/utils/banks_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/bank_model.dart';

// Proveedor singleton para el repositorio de bancos
final banksRepositoryProvider = Provider<BanksRepository>((ref) => BanksRepository());

// Proveedor reactivo para obtener bancos filtrados por userId usando Stream
final proveedorBancos = StreamProvider.family<List<BancoModelo>, String>((ref, userId) {
  final repo = ref.watch(banksRepositoryProvider);
  return repo.getBanksByUserId(userId);
});

// Proveedor para operaciones de creación/actualización/eliminación usando StateNotifier
class BancoNotifier extends StateNotifier<List<BancoModelo>> {
  final BanksRepository _repo;
  final Ref _ref;

  // Constructor que recibe el repositorio y elRef
  BancoNotifier(this._repo, this._ref) : super([]);

  // Método para eliminar un banco
  Future<void> eliminarBanco(String bancoId, String userId) async {
    // Obtiene userId del authProvider
    final authState = _ref.watch(authProvider); 
    final userIdAuth = authState.user?.uid ?? userId; // Usamos userId proporcionado o del auth
    
    await _repo.eliminarBanco(bancoId, userIdAuth);
  }

  // Método para crear un banco
  Future<void> crearBanco(BancoModelo banco) async {
    await _repo.crearBanco(banco);
  }

  // Método para actualizar un banco
  Future<void> actualizarBanco(BancoModelo banco) async {
    await _repo.actualizarBanco(banco);
  }
}

// Declaramos el StateNotifierProvider
final bancoNotifierProvider = StateNotifierProvider<BancoNotifier, List<BancoModelo>>((ref) {
  final repo = ref.watch(banksRepositoryProvider);
  return BancoNotifier(repo, ref);
});