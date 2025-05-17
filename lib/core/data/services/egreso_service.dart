import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'dart:math';

class EgresoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Generar un ID aleatorio
  String generarIdAleatorio() {
    const caracteres =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
        20, (index) => caracteres[random.nextInt(caracteres.length)]).join();
  }

  // 🔹 Agregar un nuevo egreso
  /*Future<void> addEgreso(String uid, Egreso egreso) async {
    final id = _generarIdAleatorio(); // Generar un ID aleatorio
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('egreso')
        .doc(id) // Usar el ID generado
        .set(egreso.toMap());
  }*/
  Future<void> addEgreso(String uid, Egreso egreso) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(uid)
          .collection('egreso')
          .add(egreso.toMap());

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('egreso')
          .doc(docRef.id)
          .update({'id': docRef.id});
    } catch (e) {
      throw Exception("No se pudo guardar el egreso");
    }
  }

  // 🔹 Actualizar un egreso
  Future<void> actualizarEgreso(String uid, Egreso egreso) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('egreso')
          .doc(egreso.id)
          .update(egreso.toMap());
    } catch (e) {
      throw Exception("No se pudo actualizar el egreso");
    }
  }

  // 🔹 Eliminar un egreso
  Future<void> eliminarEgreso(String uid, String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('egreso')
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception("No se pudo eliminar el egreso");
    }
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

  // Obtener el total de ingresos del mes actual en tiempo real (Stream)
  Stream<double> streamTotalIngresosMesActual(String userId) {
    final now = DateTime.now();
    final mesActual =
        _obtenerNombreMes(now.month); // Convertir a nombre del mes
    final anioActual = now.year;

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('egreso')
        .where('mes', isEqualTo: mesActual)
        .where('anio', isEqualTo: anioActual)
        .where('estado', isEqualTo: 'Pendiente')
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

  Stream<double> streamTotalGastosMesActual(String userId) {
    final now = DateTime.now();
    final mesActual = _obtenerNombreMes(now.month);
    final anioActual = now.year;

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('egreso')
        .where('mes', isEqualTo: mesActual)
        .where('anio', isEqualTo: anioActual)
        /*.where('estado', isEqualTo: 'Pendiente')*/
        .snapshots()
        .map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final valor = doc.data()['valor'];
        total += valor is num ? valor.toDouble() : 0.0;
      }
      return total;
    });
  }

  // Método para obtener el total de gastos en un rango de fechas
  Stream<double> streamTotalGastosInRange(
      String userId, DateTime start, DateTime end) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('egreso')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(end))
        /*.where('estado', isEqualTo: 'Pendiente')*/
        .snapshots()
        .map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final valor = doc.data()['valor'];
        total += valor is num ? valor.toDouble() : 0.0;
      }
      return total;
    });
  }

  Stream<List<Egreso>> obtenerEgresosFiltrados(
    String userId,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    Query query =
        _firestore.collection('users').doc(userId).collection('egreso');

    if (startDate != null && endDate != null) {
      query = query
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Egreso.fromMap({
                ...(doc.data() as Map<String, dynamic>? ?? {}),
                'id': doc.id,
              }))
          .toList();
    });
  }

  double calcularTotalEgresos(List<Egreso> egresos) {
    return egresos.fold(0.0, (sum, egreso) => sum + egreso.valor);
  }

  // Función auxiliar para convertir número de mes a nombre
  String _obtenerNombreMes(int numeroMes) {
    return [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ][numeroMes - 1];
  }
}
