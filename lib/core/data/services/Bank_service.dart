// bank_service.dart
// Servicio para operaciones CRUD con Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/bank_model.dart';

class BancoService {
  // Acceso a la subcolección 'bancos' del usuario actual
  CollectionReference _userBanks(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bancos');
  }

  // Obtiene todos los bancos de un usuario (método síncrono)
  Future<List<BancoModelo>> obtenerBancos(String userId) async {
    try {
      final QuerySnapshot snapshot = await _userBanks(userId).get();
      return snapshot.docs.map((doc) => BancoModelo.fromJson(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Error al obtener bancos: $e');
    }
  }

  // Elimina un banco específico
  Future<void> eliminarBanco(String bancoId, String userId) async {
    try {
      await _userBanks(userId).doc(bancoId).delete();
    } catch (e) {
      throw Exception('Error al eliminar banco: $e');
    }
  }
}