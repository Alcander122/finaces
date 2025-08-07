import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/investment_model.dart';

class InvestmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Referencia a la colección `investments` dentro de `users/{userId}/portafolios/{portafolioId}`
  CollectionReference<Investment> _investmentCollection(
      String userId, String portafolioId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('portafolios')
        .doc(portafolioId)
        .collection('investments')
        .withConverter<Investment>(
          fromFirestore: (snapshot, _) => Investment.fromFirestore(snapshot),
          toFirestore: (investment, _) => investment.toFirestore(),
        );
  }

  /// Obtiene las inversiones de un usuario y portafolio específico.
  Stream<List<Investment>> obtenerInvestments(
      String userId, String portafolioId) {
    return _investmentCollection(userId, portafolioId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Obtiene todas las inversiones del usuario autenticado.
  Stream<List<Investment>> obtenerTodosInvestments(String userId) {
    return _firestore
        .collectionGroup('investments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Investment.fromFirestore(doc)).toList());
  }

  /// Agrega una nueva inversión al portafolio del usuario.
  Future<void> agregarInvestment(
      String userId, String portafolioId, Investment investment) async {
    await _investmentCollection(userId, portafolioId).add(investment);
  }

  /// Elimina una inversión por su ID.
  Future<void> eliminarInvestment(
      String userId, String portafolioId, String investmentId) async {
    await _investmentCollection(userId, portafolioId)
        .doc(investmentId)
        .delete();
  }

  Future<void> eliminarInversionesDePortafolio(
      String userId, String portafolioId) async {
    try {
      final inversiones = await _firestore
          .collection('users')
          .doc(userId)
          .collection('portafolios')
          .doc(portafolioId)
          .collection('investments')
          .get();

      for (final doc in inversiones.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      //print('Error al eliminar inversiones: $e');
      rethrow;
    }
  }

  /// Actualiza una inversión existente usando su ID.
  Future<void> actualizarInvestment(String userId, String portafolioId,
      String investmentId, Investment investment) async {
    await _investmentCollection(userId, portafolioId)
        .doc(investmentId)
        .update(investment.toFirestore());
  }
}
