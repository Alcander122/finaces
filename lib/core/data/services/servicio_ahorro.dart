import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/objetivo_ahorro.dart';

/// Servicio que maneja todas las operaciones relacionadas con
/// las metas de ahorro en Firestore.
class AhorroService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _usuario = FirebaseAuth.instance.currentUser;

  /// 🔹 Obtiene todas las metas de ahorro en tiempo real (Stream).
  /// Se escucha la colección y se transforma en una lista de ObjetivoAhorro.
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

  /// 🔹 Crea una nueva meta de ahorro en Firestore.
  /// Se inicializa con montoActual = 0 y sin transacciones.
  Future<void> crearMeta({
    required String nombre,
    required double montoObjetivo,
    required DateTime fechaObjetivo,
    required DateTime fechaCreacion,
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

  /// 🔹 Agrega una transacción (depósito o retiro) a una meta existente.
  /// También actualiza el montoActual de la meta.
  Future<void> agregarTransaccion({
    required String metaId,
    required String tipo, // 'deposito' o 'retiro'
    required double monto,
    String? descripcion,
  }) async {
    final transaccion = Transaccion(
      tipo: tipo,
      monto: monto,
      fecha: DateTime.now(),
      descripcion: descripcion,
    );

    await _firestore
        .collection('users')
        .doc(_usuario?.uid)
        .collection('ahorro')
        .doc(metaId)
        .update({
      // 👉 incrementa o decrementa según sea depósito o retiro
      'montoActual': FieldValue.increment(tipo == 'deposito' ? monto : -monto),
      // 👉 añade la transacción al historial
      'transacciones': FieldValue.arrayUnion([transaccion.toMap()]),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  /// 🔹 Elimina una meta de ahorro por su ID.
  Future<void> eliminarMeta(String metaId) async {
    await _firestore
        .collection('users')
        .doc(_usuario?.uid)
        .collection('ahorro')
        .doc(metaId)
        .delete();
  }

  /// 🔹 Obtiene una meta de ahorro por su ID.
  /// Esto se usa, por ejemplo, para calcular el maxMonto en el diálogo.
  Future<ObjetivoAhorro> obtenerMetaPorId(String metaId) async {
    final doc = await _firestore
        .collection('users')
        .doc(_usuario?.uid)
        .collection('ahorro')
        .doc(metaId)
        .get();

    if (!doc.exists) {
      throw Exception("Meta no encontrada");
    }

    return ObjetivoAhorro.desdeFirestore(doc);
  }
}
