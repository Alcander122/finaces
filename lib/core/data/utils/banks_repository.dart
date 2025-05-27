import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/bank_model.dart';

class BanksRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtiene referencia a la subcolección de bancos del usuario
  CollectionReference _userBanks(String userId) {
    return _firestore.collection('users').doc(userId).collection('bancos');
  }

  // Stream de bancos con datos en tiempo real
  Stream<List<BancoModelo>> getBanksByUserId(String userId) {
    return _userBanks(userId).snapshots().map((snapshot) => 
      snapshot.docs.map((doc) {
        // Combina datos del documento con su ID
        final data = doc.data() as Map<String, dynamic>;
        return BancoModelo.fromJson({
          ...data,
          'id': doc.id, // Agrega ID del documento
        });
      }).toList()
    );
  }

  // Crea nuevo banco y devuelve su ID generado
  Future<String> crearBanco(BancoModelo banco) async {
    final docRef = await _userBanks(banco.userId).add(banco.toJson());
    return docRef.id; // Retorna ID generado por Firestore
  }

  // Actualiza banco existente
  Future<void> actualizarBanco(BancoModelo banco) {
    return _userBanks(banco.userId)
        .doc(banco.id)
        .update(banco.toJson());
  }

  // Elimina banco
  Future<void> eliminarBanco(String bancoId, String userId) {
    return _userBanks(userId).doc(bancoId).delete();
  }
}