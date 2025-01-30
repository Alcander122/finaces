import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'dart:math';

class EgresoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Generar un ID aleatorio
  String _generarIdAleatorio() {
    const caracteres =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
        20, (index) => caracteres[random.nextInt(caracteres.length)]).join();
  }

  // 🔹 Agregar un nuevo egreso
  Future<void> addEgreso(String uid, Egreso egreso) async {
    final id = _generarIdAleatorio(); // Generar un ID aleatorio
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('egreso')
        .doc(id) // Usar el ID generado
        .set(egreso.toMap());
  }

  // 🔹 Actualizar un egreso
  Future<void> actualizarEgreso(String uid, Egreso egreso) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('egreso')
        .doc(egreso.id)
        .update(egreso.toMap());
  }

  // 🔹 Eliminar un egreso
  Future<void> eliminarEgreso(String uid, String id) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('egreso')
        .doc(id)
        .delete();
  }

  // 🔹 Obtener egresos ordenados por año y mes
  Stream<List<Egreso>> obtenerEgresos(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('egreso')
        .orderBy('anio', descending: true)
        .orderBy('mes')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();
        return Egreso.fromMap(data)
            .copyWith(id: doc.id); // Asegurar que el ID esté presente
      }).toList();
    });
  }

  // 🔹 Obtener la suma de egresos pendientes
  Stream<double> streamTotalGastos(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('egreso')
        .where('estado', isEqualTo: 'Pendiente')
        .snapshots()
        .map((snapshot) {
      double totalGastos = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final valor = data['valor'];
        if (valor is num) {
          totalGastos += valor.toDouble();
        }
      }
      return totalGastos;
    });
  }
}
