// lib/core/data/services/egreso_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'dart:math';

/// Servicio para manejar operaciones CRUD y consultas de egresos
class EgresoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Genera un ID aleatorio para nuevos egresos
  ///
  /// Uso:
  /// - Cuando se crea un nuevo egreso antes de guardarlo en Firestore
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
      throw Exception("No se pudo guardar el egreso");
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
      throw Exception("No se pudo actualizar el egreso");
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
      throw Exception("No se pudo eliminar el egreso");
    }
  }

  /// Obtiene todos los egresos del usuario ordenados por fecha
  Stream<List<Egreso>> obtenerEgresos(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('egreso')
        .orderBy('fechaPago')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();
        return Egreso.fromMap(data).copyWith(id: doc.id);
      }).toList();
    });
  }

  /// Método OBSOLETO - No se usa directamente en la UI
  ///
  /// Este método solo filtra por estado 'Pendiente' sin considerar fechas,
  /// por lo que no es adecuado para mostrar en las tarjetas resumen.
  /// Se mantiene para compatibilidad con código existente.
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

  /// Obtiene el total de gastos en un rango de fechas específico
  ///
  /// Este es el método clave que se usa en filteredTotalGastosProvider
  /// para calcular los gastos según el filtro seleccionado
  ///
  /// IMPORTANTE:
  /// - Usa Timestamp.fromDate() para convertir fechas a formato compatible con Firestore
  /// - Asegura que todos los registros en el rango de fecha sean incluidos
  Stream<double> streamTotalGastosInRange(
      String userId, DateTime start, DateTime end) {
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
    });
  }

  /// Obtiene el total de gastos del mes actual
  ///
  /// NOTA: Este método se mantiene para compatibilidad con pantallas como el Home
  Stream<double> streamTotalGastosMesActual(String userId) {
    final now = DateTime.now();
    // Cálculo preciso del último día del mes
    final inicioMes = DateTime(now.year, now.month, 1);
    final finMes = DateTime(now.year, now.month + 1, 0);
    // Asegurar que cubre todo el día (incluyendo 23:59:59.999)
    final inicioMesAjustado = inicioMes;
    final finMesAjustado =
        finMes.add(Duration(days: 1)).subtract(Duration(milliseconds: 1));

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

  /// Obtiene los egresos filtrados por rango de fechas (usado por la gráfica)
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

  /// Calcula el total de una lista de egresos
  double calcularTotalEgresos(List<Egreso> egresos) {
    return egresos.fold(0.0, (sum, egreso) => sum + egreso.valor);
  }
}
