import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/ingreso.model.dart';

class IngresosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Guardar un nuevo ingreso
  Future<String> guardarIngreso(String userId, Ingreso ingreso) async {
    try {
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
    } catch (e) {
      throw Exception("No se pudo guardar el ingreso: $e");
    }
  }

  // Obtener todos los ingresos
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

  Future<void> actualizarIngreso(
      String userId, String ingresoId, Ingreso ingreso) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ingresos')
          .doc(ingresoId)
          .update(ingreso.toMap());
    } catch (e) {
      throw Exception("No se pudo actualizar el ingreso: $e");
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
    } catch (e) {
      throw Exception("No se pudo eliminar el ingreso: $e");
    }
  }

  // Total de ingresos en tiempo real (Stream)
  Stream<double> streamTotalIngresos(String userId) {
    try {
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
      }).handleError((error) {
        // Manejar el error si es necesario
        //print("Error en streamTotalIngresos: $error");
        throw Exception("Error en streamTotalIngresos: $error");
      });
    } catch (e) {
      throw Exception("Error en streamTotalIngresos: $e");
    }
  }

  // Total de ingresos en un rango de fechas
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
        //print("Error en streamTotalIngresosInRange: $error");
        throw Exception("Error en streamTotalIngresosInRange: $error");
      });
    } catch (e) {
      throw Exception("Error en streamTotalIngresosInRange: $e");
    }
  }

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
        //print("Error en obtenerIngresosFiltrados: $error");
        throw Exception("Error en obtenerIngresosFiltrados: $error");
      });
    } catch (e) {
      throw Exception("Error en obtenerIngresosFiltrados: $e");
    }
  }

  double calcularTotalIngresos(List<Ingreso> ingresos) {
    try {
      return ingresos.fold(0.0, (sum, ingreso) => sum + ingreso.valor);
    } catch (e) {
      throw Exception("Error al calcular el total de ingresos: $e");
    }
  }

  // Método actualizado para obtener el total de ingresos del mes actual
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
        //print("Error en streamTotalIngresosMesActual: $error");
        throw Exception("Error en streamTotalIngresosMesActual: $error");
      });
    } catch (e) {
      throw Exception("Error en streamTotalIngresosMesActual: $e");
    }
  }
}
