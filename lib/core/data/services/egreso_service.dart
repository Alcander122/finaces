// lib/core/data/services/egreso_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/core/errors/handlers/db_error_handler.dart';
import 'dart:math';

/// Servicio para manejar operaciones CRUD y consultas de egresos
class EgresoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Genera un ID aleatorio para nuevos egresos
  String generarIdAleatorio() {
    const caracteres =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
        20, (index) => caracteres[random.nextInt(caracteres.length)]).join();
  }

  /// Agrega un nuevo egreso a Firestore
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
      // Lanzamos el error ya traducido por nuestro handler
      throw DbErrorHandler.handle(e);
    }
  }

  /// Actualiza un egreso existente en Firestore
  Future<void> actualizarEgreso(String uid, Egreso egreso) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('egreso')
          .doc(egreso.id)
          .update(egreso.toMap());
    } catch (e) {
      throw DbErrorHandler.handle(e);
    }
  }

  /// Elimina un egreso de Firestore
  Future<void> eliminarEgreso(String uid, String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('egreso')
          .doc(id)
          .delete();
    } catch (e) {
      throw DbErrorHandler.handle(e);
    }
  }

  /// Obtiene todos los egresos del usuario ordenados por fecha
  Stream<List<Egreso>> obtenerEgresos(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('egreso')
        .orderBy('fechaPago', descending: true) // Mejor UX: Más recientes primero
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();
        return Egreso.fromMap(data).copyWith(id: doc.id);
      }).toList();
    }).handleError((error) {
      // Interceptamos errores del stream
      throw DbErrorHandler.handle(error);
    });
  }

  /// Obtiene los egresos filtrados por un rango de fechas
  Stream<List<Egreso>> obtenerEgresosFiltrados(String uid, DateTime? start, DateTime? end) {
    Query query = _firestore.collection('users').doc(uid).collection('egreso');

    if (start != null) {
      query = query.where('fechaPago', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    }
    if (end != null) {
      query = query.where('fechaPago', isLessThanOrEqualTo: Timestamp.fromDate(end));
    }

    return query.orderBy('fechaPago', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Egreso.fromMap(doc.data() as Map<String, dynamic>).copyWith(id: doc.id);
      }).toList();
    }).handleError((error) {
      throw DbErrorHandler.handle(error);
    });
  }

  /// Obtiene el total de gastos en un rango de fechas específico
  Stream<double> streamTotalGastosInRange(String userId, DateTime start, DateTime end) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('egreso')
        .where('fechaPago', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('fechaPago', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final valor = doc.data()['valor'];
        total += valor is num ? valor.toDouble() : 0.0;
      }
      return total;
    }).handleError((error) {
      throw DbErrorHandler.handle(error);
    });
  }

  /// Obtiene el total de gastos del mes actual
  Stream<double> streamTotalGastosMesActual(String userId) {
    final now = DateTime.now();
    final inicioMes = DateTime(now.year, now.month, 1);
    final finMes = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);

    return streamTotalGastosInRange(userId, inicioMes, finMes);
  }
  
  /// Método OBSOLETO
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
    }).handleError((error) => throw DbErrorHandler.handle(error));
  }
  
  double calcularTotalEgresos(List<Egreso> egresos) {
      return egresos.fold(0.0, (sum, item) => sum + item.valor);
  }
}
