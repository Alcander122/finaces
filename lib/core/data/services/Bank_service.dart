import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/bank_model.dart';

class BancoService {
  CollectionReference _userBanks(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bancos');
  }

  Future<List<BancoModelo>> obtenerBancos(String userId) async {
    try {
      final QuerySnapshot snapshot = await _userBanks(userId).get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final banco = BancoModelo.fromJson(data);
            // Omite bancos con id o userId vacíos
            return banco.id.isNotEmpty && banco.userId.isNotEmpty
                ? banco
                : null;
          })
          .where((banco) => banco != null)
          .cast<BancoModelo>()
          .toList();
    } catch (e) {
      throw Exception('Error al obtener bancos: $e');
    }
  }

  Future<void> eliminarBanco(String bancoId, String userId) async {
    try {
      await _userBanks(userId).doc(bancoId).delete();
    } catch (e) {
      throw Exception('Error al eliminar banco: $e');
    }
  }
}
