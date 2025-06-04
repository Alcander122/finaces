import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/egreso_model.dart';
//import 'package:flutter/foundation.dart';
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
        .orderBy('fechaPago') // Ordenar por fechaPago de menor a mayor
        /*.orderBy('anio', descending: true)
        .orderBy('mes')*/
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
  Stream<double> streamTotalIngresosMesActual(
    String userId,
  ) {
    final now = DateTime.now();
    final inicioMes = DateTime(now.year, now.month, 1);
    final finMes = DateTime(now.year, now.month + 1, 0);
    final finMesAjustado = finMes
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('egreso')
        .where('fechaPago', isGreaterThanOrEqualTo: inicioMes)
        .where('fechaPago', isLessThanOrEqualTo: finMesAjustado)
        .snapshots()
        .map((snapshot) {
      double totalIngresos = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Obtiene el valor y asegúrate de que sea numérico
        final dynamic valor = data['valor'];
        if (valor != null) {
          if (valor is num) {
            totalIngresos += valor.toDouble();
          } else if (valor is String) {
            totalIngresos += double.tryParse(valor) ?? 0.0;
          }
        }
      }

      return totalIngresos; // Devuelve el total de gastos
    });
  }

  Stream<double> streamTotalGastosMesActual(String userId) {
    final now = DateTime.now();

    // CORRECCIÓN CLAVE: Cálculo preciso del último día del mes
    final inicioMes = DateTime(now.year, now.month, 1);
    final finMes =  DateTime(now.year, now.month + 1, 0); // <-- Cambio importante

    // Asegurar que cubre todo el día (incluyendo 23:59:59)
    final inicioMesAjustado = inicioMes;
    final finMesAjustado =finMes.add(Duration(days: 1)).subtract(Duration(milliseconds: 1));

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('egreso')
        .where('fechaPago', isGreaterThanOrEqualTo: inicioMesAjustado)
        .where('fechaPago', isLessThanOrEqualTo: finMesAjustado)
        .snapshots()
        .map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final dynamic valor = doc.data()['valor'];

        if (valor != null) {
          if (valor is num) {
            total += valor.toDouble();
          } else if (valor is String) {
            total += double.tryParse(valor) ?? 0.0;
          }
        }
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
        .where('fechaPago', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('fechaPago', isLessThanOrEqualTo: Timestamp.fromDate(end))
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
          .where('fechaPago',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('fechaPago', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
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
}
