// lib/core/data/services/investment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/investment_model.dart';

/// Servicio para gestionar inversiones en Firestore
class InvestmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Referencia a la colección 'investments' dentro de un portafolio
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

  /// Stream en tiempo real: emite lista completa cada vez que cambia un documento
  Stream<List<Investment>> obtenerInversionesEnTiempoReal(
      String userId, String portafolioId) {
    return _investmentCollection(userId, portafolioId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Agregar inversión con ID controlado (evita .add() para consistencia)
  Future<void> agregarInvestment(
      String userId, String portafolioId, Investment investment) async {
    await _investmentCollection(userId, portafolioId)
        .doc(investment.id)
        .set(investment);
  }

  /// Actualizar inversión existente
  Future<void> actualizarInvestment(String userId, String portafolioId,
      String investmentId, Investment investment) async {
    await _investmentCollection(userId, portafolioId)
        .doc(investmentId)
        .update(investment.toFirestore());
  }

  /// Eliminar una inversión
  Future<void> eliminarInvestment(
      String userId, String portafolioId, String investmentId) async {
    await _investmentCollection(userId, portafolioId)
        .doc(investmentId)
        .delete();
  }

  /// Eliminar todas las inversiones de un portafolio
  Future<void> eliminarInversionesDePortafolio(
      String userId, String portafolioId) async {
    final snapshot = await _investmentCollection(userId, portafolioId).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Obtener todas las inversiones del usuario (collectionGroup)
  Stream<List<Investment>> obtenerTodosInvestments(String userId) {
    return _firestore
        .collectionGroup('investments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Investment.fromFirestore(doc)).toList());
  }
}
