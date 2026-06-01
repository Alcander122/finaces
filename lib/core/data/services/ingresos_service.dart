// lib/core/data/services/ingresos_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/ingreso.model.dart';

/// Servicio para manejar operaciones CRUD y consultas de ingresos
class IngresosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Guarda un nuevo ingreso en Firestore
  Future<String> guardarIngreso(String userId, Ingreso ingreso) async {
    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('ingresos')
        .add(ingreso.toMap());
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('ingresos')
        .doc(docRef.id)
        .update({'id': docRef.id});
    return docRef.id;
  }

  /// Método actualizado para obtener el total de ingresos del mes actual
  ///
  /// IMPORTANTE: Usa DateUtils para consistencia con otros cálculos
  Stream<double> streamTotalIngresosMesActual(String userId) {
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      // Calcular el último día del mes a las 23:59:59.999 para incluir todos los datos del último día
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0)
          .add(const Duration(days: 1))
          .subtract(const Duration(microseconds: 1));

      return _firestore
          .collection('users')
          .doc(userId)
          .collection('ingresos')
          .where('fechaIngreso',
              isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .where('fechaIngreso',
              isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfMonth))
          .snapshots()
          .map((snapshot) {
        double totalIngresos = 0.0;
        for (var doc in snapshot.docs) {
          final valor = doc.data()['valor'];
          totalIngresos += valor is num ? valor.toDouble() : 0.0;
        }
        return totalIngresos;
      }).handleError((error) {
        throw Exception("Error en streamTotalIngresosMesActual: $error");
      });
    } catch (e) {
      throw Exception("Error en streamTotalIngresosMesActual: $e");
    }
  }

  /// Obtiene todos los ingresos del usuario
  Future<List<Ingreso>> obtenerIngresos(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ingresos')
          .get();
      return snapshot.docs
          .map((doc) => Ingreso.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e) {
      throw Exception("No se pudieron obtener los ingresos: $e");
    }
  }

  /// Obtiene todos los ingresos del usuario ordenados por fecha como un Stream
  Stream<List<Ingreso>> streamIngresos(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('ingresos')
        .orderBy('fechaIngreso', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();
        return Ingreso.fromMap({...data, 'id': doc.id});
      }).toList();
    }).handleError((error) {
      throw Exception("Error en streamIngresos: $error");
    });
  }

  /// Actualiza un ingreso existente en Firestore
  Future<void> actualizarIngreso(
      String userId, String ingresoId, Ingreso ingreso) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('ingresos')
        .doc(ingresoId)
        .update(ingreso.toMap());
  }

  /// Elimina un ingreso de Firestore
  Future<void> eliminarIngreso(String userId, String ingresoId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('ingresos')
        .doc(ingresoId)
        .delete();
  }

  /// Obtiene el total de ingresos en un rango de fechas específico
  ///
  /// Este es el método clave que se usa en filteredIngresosProvider
  Stream<double> streamTotalIngresosInRange(
      String userId, DateTime start, DateTime end) {
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('ingresos')
          .where('fechaIngreso',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('fechaIngreso', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .snapshots()
          .map((snapshot) {
        double total = 0.0;
        for (var doc in snapshot.docs) {
          final valor = doc.data()['valor'];
          total += valor is num ? valor.toDouble() : 0.0;
        }
        return total;
      }).handleError((error) {
        throw Exception("Error en streamTotalIngresosInRange: $error");
      });
    } catch (e) {
      throw Exception("Error en streamTotalIngresosInRange: $e");
    }
  }

  /// Obtiene los ingresos filtrados por rango de fechas (usado por la gráfica)
  Stream<List<Ingreso>> obtenerIngresosFiltrados(
    String userId,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    try {
      Query query =
          _firestore.collection('users').doc(userId).collection('ingresos');
      if (startDate != null && endDate != null) {
        query = query
            .where('fechaIngreso',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('fechaIngreso',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          if (data == null || data is! Map) {
            return Ingreso.fromMap({'id': doc.id});
          }
          return Ingreso.fromMap({
            ...data as Map<String, dynamic>,
            'id': doc.id,
          });
        }).toList();
      }).handleError((error) {
        throw Exception("Error en obtenerIngresosFiltrados: $error");
      });
    } catch (e) {
      throw Exception("Error en obtenerIngresosFiltrados: $e");
    }
  }

  /// Calcula el total de una lista de ingresos
  double calcularTotalIngresos(List<Ingreso> ingresos) {
    try {
      return ingresos.fold(0.0, (sum, ingreso) => sum + ingreso.valor);
    } catch (e) {
      throw Exception("Error al calcular el total de ingresos: $e");
    }
  }
}
