// lib/core/data/services/investment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/investment_model.dart';

class InvestmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Referencia a la subcolección `investments`
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

  /// OBTIENE INVERSIONES DE UN PORTAFOLIO EN TIEMPO REAL
  /// Usa: .get() inicial + .snapshots() por documento
  Stream<List<Investment>> obtenerInvestments(
      String userId, String portafolioId) async* {
    final collection = _investmentCollection(userId, portafolioId);

    // 1. Carga inicial
    final initialSnapshot = await collection.get();
    final currentList = initialSnapshot.docs.map((doc) => doc.data()).toList();
    yield currentList;

    // 2. Escuchar cambios en cada inversión
    for (final doc in initialSnapshot.docs) {
      yield* doc.reference.snapshots().map((docSnap) {
        final updatedList = currentList.toList();
        final index = updatedList.indexWhere((i) => i.id == doc.id);

        if (docSnap.exists) {
          final updatedInvestment = docSnap.data()!;
          if (index >= 0) {
            updatedList[index] = updatedInvestment;
          } else {
            updatedList.add(updatedInvestment);
          }
        } else if (index >= 0) {
          updatedList.removeAt(index);
        }

        return updatedList;
      });
    }
  }

  /// OBTIENE TODAS LAS INVERSIONES DEL USUARIO (collectionGroup)
  /// → Funciona porque filtra por `userId` y tu regla permite `read`
  Stream<List<Investment>> obtenerTodosInvestments(String userId) {
    return _firestore
        .collectionGroup('investments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Investment.fromFirestore(doc)).toList());
  }

  /// Agregar inversión
  Future<void> agregarInvestment(
      String userId, String portafolioId, Investment investment) async {
    await _investmentCollection(userId, portafolioId).add(investment);
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

  /// Actualizar inversión
  Future<void> actualizarInvestment(String userId, String portafolioId,
      String investmentId, Investment investment) async {
    await _investmentCollection(userId, portafolioId)
        .doc(investmentId)
        .update(investment.toFirestore());
  }
}
