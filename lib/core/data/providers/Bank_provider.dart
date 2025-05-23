// Proveedor para gestionar el estado de los bancos
import 'package:finances/core/data/services/Bank_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/bank_model.dart';

// Proveedor para acceder al estado de los bancos
final proveedorBancos =
    StateNotifierProvider<ControladorBancos, List<BancoModelo>>((ref) {
  return ControladorBancos();
});

class ControladorBancos extends StateNotifier<List<BancoModelo>> {
  ControladorBancos() : super([]) {
    _cargarBancos();
  }

  final BancoService bancoService = BancoService();

  // Cargar bancos del usuario actual
  Future<void> _cargarBancos([String userId = '']) async {
    try {
      final bancos = await bancoService.obtenerBancos(userId);
      state = bancos;
    } catch (e) {
      print("Error al cargar bancos iniciales: $e");
    }
  }

  // Agregar un nuevo banco
  Future<void> agregarBanco(BancoModelo banco, String userId) async {
    try {
      await bancoService.agregarBanco(banco, userId);
      final nuevoBanco = await bancoService.obtenerBancos(userId).then(
          (value) =>
              value.lastWhere((b) => b.numeroCuenta == banco.numeroCuenta));
      state = [...state, nuevoBanco];
    } catch (e) {
      print("Error al agregar banco: $e");
    }
  }

  // Actualizar un banco existente
  Future<void> actualizarBanco(BancoModelo bancoActualizado) async {
    try {
      await bancoService.actualizarBanco(bancoActualizado);
      state = state.map((banco) {
        if (banco.id == bancoActualizado.id) return bancoActualizado;
        return banco;
      }).toList();
    } catch (e) {
      print("Error al actualizar banco: $e");
    }
  }

  // Eliminar un banco
  Future<void> eliminarBanco(String bancoId) async {
    try {
      await bancoService.eliminarBanco(bancoId);
      state = state.where((banco) => banco.id != bancoId).toList();
    } catch (e) {
      print("Error al eliminar banco: $e");
    }
  }
}
