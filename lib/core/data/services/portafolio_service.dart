import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/portafolio_model.dart';

class PortafolioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Portafolio> _portafolioCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('portafolios')
        .withConverter<Portafolio>(
          fromFirestore: (snapshot, _) => Portafolio.fromFirestore(snapshot),
          toFirestore: (portafolio, _) => portafolio.toFirestore(),
        );
  }

  Stream<List<Portafolio>> obtenerPortafoliosEnTiempoReal(String userId) {
    return _portafolioCollection(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> agregarPortafolio(String userId, Portafolio portafolio) async {
    await _portafolioCollection(userId).doc(portafolio.id).set(portafolio);
  }

  Future<void> eliminarPortafolio(String userId, String portafolioId) async {
    await _portafolioCollection(userId).doc(portafolioId).delete();
  }

  Future<void> actualizarPortafolio(
      String userId, Portafolio portafolio) async {
    await _portafolioCollection(userId)
        .doc(portafolio.id)
        .update(portafolio.toFirestore());
  }
}
