// lib/core/data/services/portafolio_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/portafolio_model.dart';
import 'package:finances/core/data/services/investment_service.dart';

class PortafolioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Referencia a la colección de portafolios del usuario
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

  /// Obtiene los portafolios en tiempo real escuchando los cambios en la colección
  Stream<List<Portafolio>> obtenerPortafoliosEnTiempoReal(String userId) {
    return _portafolioCollection(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Agregar portafolio
  Future<void> agregarPortafolio(String userId, Portafolio portafolio) async {
    await _portafolioCollection(userId).doc(portafolio.id).set(portafolio);
  }

  /// Eliminar portafolio + sus inversiones
  Future<void> eliminarPortafolio(String userId, String portafolioId) async {
    try {
      await InvestmentService()
          .eliminarInversionesDePortafolio(userId, portafolioId);
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('portafolios')
          .doc(portafolioId)
          .delete();
    } catch (e) {
      //print('Error al eliminar portafolio: $e');
      rethrow;
    }
  }

  /// Actualizar portafolio
  Future<void> actualizarPortafolio(
      String userId, Portafolio portafolio) async {
    await _portafolioCollection(userId)
        .doc(portafolio.id)
        .update(portafolio.toFirestore());
  }
}
