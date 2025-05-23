// Servicio para interactuar con Firebase Firestore
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/bank_model.dart';

class BancoService {
  final CollectionReference _coleccionBancos =
      FirebaseFirestore.instance.collection('bancos');

  // Obtener bancos del usuario autenticado
  Future<List<BancoModelo>> obtenerBancos(String userId) async {
    try {
      final QuerySnapshot querySnapshot =
          await _coleccionBancos.where('user_id', isEqualTo: userId).get();
      return querySnapshot.docs.map((doc) {
        final datos = doc.data() as Map<String, dynamic>;
        return BancoModelo(
          id: doc.id,
          nombre: datos['nombre'],
          tasaInteres: datos['tasa_interes']?.toDouble() ?? 0.0,
          comisionMensual: datos['comision_mensual']?.toDouble() ?? 0.0,
          beneficios: datos['beneficios'] ?? 0,
          numeroCuenta: datos['numero_cuenta'] ?? '',
        );
      }).toList();
    } catch (e) {
      print("Error al obtener bancos: $e");
      rethrow;
    }
  }

  // Agregar un nuevo banco
  Future<void> agregarBanco(BancoModelo banco, String userId) async {
    try {
      await _coleccionBancos.add({
        ...banco.toJson(),
        'user_id': userId, // Asociar banco al usuario
      });
    } catch (e) {
      print("Error al agregar banco: $e");
      rethrow;
    }
  }

  // Actualizar información de un banco
  Future<void> actualizarBanco(BancoModelo bancoActualizado) async {
    try {
      await _coleccionBancos
          .doc(bancoActualizado.id)
          .update(bancoActualizado.toJson());
    } catch (e) {
      print("Error al actualizar banco: $e");
      rethrow;
    }
  }

  // Eliminar un banco
  Future<void> eliminarBanco(String bancoId) async {
    try {
      await _coleccionBancos.doc(bancoId).delete();
    } catch (e) {
      print("Error al eliminar banco: $e");
      rethrow;
    }
  }
}
