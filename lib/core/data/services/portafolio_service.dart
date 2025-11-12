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

  /// OBTIENE PORTAFOLIOS EN TIEMPO REAL SIN REQUERIR `allow list`
  /// Usa: .get() inicial + .snapshots() en cada documento
  Stream<List<Portafolio>> obtenerPortafoliosEnTiempoReal(
      String userId) async* {
    final collection = _portafolioCollection(userId);

    // 1. Carga inicial: obtener todos los documentos (permitido por 'read')
    final initialSnapshot = await collection.get();
    final currentList = initialSnapshot.docs.map((doc) => doc.data()).toList();

    // Emitir lista inicial
    yield currentList;

    // 2. Escuchar cambios en CADA documento individualmente
    // → .snapshots() en documento = permitido por 'read'
    for (final doc in initialSnapshot.docs) {
      yield* doc.reference.snapshots().map((docSnap) {
        final updatedList = currentList.toList(); // Copia para no mutar
        final index = updatedList.indexWhere((p) => p.id == doc.id);

        if (docSnap.exists) {
          final updatedPortafolio = docSnap.data()!;
          if (index >= 0) {
            updatedList[index] = updatedPortafolio; // Actualizar
          } else {
            updatedList.add(updatedPortafolio); // Nuevo
          }
        } else if (index >= 0) {
          updatedList.removeAt(index); // Eliminado
        }

        return updatedList;
      });
    }
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
