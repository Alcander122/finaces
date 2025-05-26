import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/bank_model.dart';

class BanksRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para obtener la subcolección de bancos de un usuario
  CollectionReference _userBanks(String userId) {
    return _firestore.collection('users').doc(userId).collection('bancos');
  }

  // Obtiene un flujo de bancos asociados a un userId
  Stream<List<BancoModelo>> getBanksByUserId(String userId) {
    return _userBanks(userId).snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => BancoModelo.fromJson(doc.data() as Map<String, dynamic>)).toList()
    );
  }

  // Crea un nuevo banco en Firestore
  Future<void> crearBanco(BancoModelo banco) {
    return _userBanks(banco.userId).add(banco.toJson()..remove('id'));
  }

  // Actualiza un banco existente en Firestore
  Future<void> actualizarBanco(BancoModelo banco) {
    return _userBanks(banco.userId).doc(banco.id).update(banco.toJson());
  }

  // Elimina un banco por ID y userId
  Future<void> eliminarBanco(String bancoId, String userId) {
    return _userBanks(userId).doc(bancoId).delete();
  }
}