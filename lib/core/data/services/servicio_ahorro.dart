import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/objetivo_ahorro.dart';

class AhorroService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _usuario = FirebaseAuth.instance.currentUser;

  Stream<List<ObjetivoAhorro>> obtenerMetas() {
    return _firestore
        .collection('users')
        .doc(_usuario?.uid)
        .collection('ahorro')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ObjetivoAhorro.desdeFirestore(doc))
            .toList());
  }

  Future<void> crearMeta({
    required String nombre,
    required double montoObjetivo,
    required DateTime fechaObjetivo,
  }) async {
    await _firestore
        .collection('users')
        .doc(_usuario?.uid)
        .collection('ahorro')
        .add({
      'usuarioId': _usuario?.uid,
      'nombre': nombre,
      'montoActual': 0.0,
      'montoObjetivo': montoObjetivo,
      'fechaObjetivo': fechaObjetivo,
      'transacciones': [],
      'fechaCreacion': FieldValue.serverTimestamp(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  Future<void> agregarTransaccion({
    required String metaId,
    required String tipo,
    required double monto,
  }) async {
    final transaccion = Transaccion(
      tipo: tipo,
      monto: monto,
      // Asegúrate de que fecha no sea null
      fecha: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(_usuario?.uid)
        .collection('ahorro')
        .doc(metaId)
        .update({
      'montoActual': FieldValue.increment(tipo == 'deposito' ? monto : -monto),
      'transacciones': FieldValue.arrayUnion([transaccion.toMap()]),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  Future<void> eliminarMeta(String metaId) async {
    await _firestore
        .collection('users')
        .doc(_usuario?.uid)
        .collection('ahorro')
        .doc(metaId)
        .delete();
  }
}
