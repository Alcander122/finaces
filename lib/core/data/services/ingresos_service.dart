import 'package:cloud_firestore/cloud_firestore.dart';

class IngresosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Guardar un nuevo ingreso
  Future<String> guardarIngreso(
      String userId, Map<String, dynamic> ingreso) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ingresos')
          .add(ingreso);
      print("✅ Ingreso guardado exitosamente: ID ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print("❌ Error al guardar ingreso: $e");
      throw Exception("No se pudo guardar el ingreso");
    }
  }

  // Obtener todos los ingresos
  Future<List<Map<String, dynamic>>> obtenerIngresos(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ingresos')
          .get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print("❌ Error al obtener ingresos: $e");
      throw Exception("No se pudieron obtener los ingresos");
    }
  }

  // Actualizar un ingreso existente
  Future<void> actualizarIngreso(
      String userId, String ingresoId, Map<String, dynamic> ingreso) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ingresos')
          .doc(ingresoId)
          .update(ingreso);
      print("✅ Ingreso actualizado exitosamente: ID $ingresoId");
    } catch (e) {
      print("❌ Error al actualizar ingreso: $e");
      throw Exception("No se pudo actualizar el ingreso");
    }
  }

  // Eliminar un ingreso por su ID
  Future<void> eliminarIngreso(String userId, String ingresoId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ingresos')
          .doc(ingresoId)
          .delete();
      print("✅ Ingreso eliminado exitosamente: ID $ingresoId");
    } catch (e) {
      print("❌ Error al eliminar ingreso: $e");
      throw Exception("No se pudo eliminar el ingreso");
    }
  }

  // Obtener el total de ingresos en tiempo real (Stream)
  Stream<double> streamTotalIngresos(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('ingresos')
        .snapshots()
        .map((snapshot) {
      double totalIngresos = 0.0;
      for (var doc in snapshot.docs) {
        final valor = doc.data()['valor'];
        totalIngresos += valor is num ? valor.toDouble() : 0.0;
      }
      return totalIngresos;
    });
  }

  // Obtener el total de gastos en tiempo real (Stream)
  Stream<double> streamTotalGastos(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('gastos')
        .snapshots()
        .map((snapshot) {
      double totalGastos = 0.0;
      for (var doc in snapshot.docs) {
        final valor = doc.data()['valor'];
        totalGastos += valor is num ? valor.toDouble() : 0.0;
      }
      return totalGastos;
    });
  }
}
