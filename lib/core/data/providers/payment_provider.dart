import 'dart:async';
import 'package:finances/core/data/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/pago_model.dart';

/// Proveedor de estado para la gestión de pagos del usuario.
/// Maneja la obtención, adición, edición y eliminación de pagos desde Firestore.
final paymentProvider = StateNotifierProvider.family<PaymentNotifier,
    AsyncValue<List<Pago>>, String>((ref, userId) {
  return PaymentNotifier(userId);
});

/// Notificador de estado para la lista de pagos.
class PaymentNotifier extends StateNotifier<AsyncValue<List<Pago>>> {
  final String userId;

  /// Referencia a la colección de pagos del usuario en Firestore.
  CollectionReference get _pagosCollection => FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('pagos');

  StreamSubscription<QuerySnapshot>? _subscription;

  PaymentNotifier(this.userId) : super(const AsyncValue.loading()) {
    _init();
  }

  /// Inicializa el listener a la colección de pagos en Firestore.
  Future<void> _init() async {
    try {
      if (userId.isEmpty) {
        state = AsyncValue.error(
            "User ID no puede estar vacío", StackTrace.current);
        return;
      }
      // Escucha cambios en la colección de pagos
      _subscription = _pagosCollection.snapshots().listen((snapshot) {
        final pagos = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return Pago(
            id: doc.id, // El ID del documento de Firestore
            descripcion: (data?['descripcion']) ?? '',
            monto: (data?['monto'] as num?)?.toDouble() ?? 0.0,
            fechaVencimiento:
                (data?['fechaVencimiento'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
            estaProgramado: data?['estaProgramado'] ?? false,
            notificacionAntes: data?['notificacionAntes'] ?? 1,
            frecuenciaRecurrencia: data?['frecuenciaRecurrencia'] ?? 'mensual',
          );
        }).toList();
        state = AsyncValue.data(pagos);
      }, onError: (e) {
        state = AsyncValue.error(e, StackTrace.current);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Agrega un nuevo pago a Firestore y programa la notificación si es recurrente.
  Future<void> agregarPago(Pago pago) async {
    try {
      // Agrega el pago a Firestore y obtiene la referencia del documento
      final docRef = await _pagosCollection.add(pago.toMap());

      // Verifica si el pago es programado/recurrente
      if (pago.estaProgramado) {
        // Es crucial pasar el ID generado por Firestore al objeto Pago
        // para que el servicio de notificación pueda usarlo.
        final pagoConId = pago.copyWith(id: docRef.id);
        debugPrint("Agregando pago programado con ID: ${pagoConId.id}");

        // Programa la notificación recurrente pasando el objeto completo
        await NotificationService().scheduleRecurringNotification(pagoConId);
      }
    } catch (e) {
      debugPrint("Error en agregarPago: $e");
      rethrow; // Relanza el error para que pueda ser manejado por el llamador
    }
  }

  /// Edita un pago existente en Firestore y actualiza la notificación si es necesario.
  Future<void> editarPago(Pago updatedPago) async {
    try {
      final DocumentReference docRef = _pagosCollection.doc(updatedPago.id);
      final DocumentSnapshot snapshot = await docRef.get();

      // Verifica si el documento existe
      if (snapshot.exists) {
        // Obtiene el pago anterior desde Firestore usando fromFirestore
        final previousPago = Pago.fromFirestore(snapshot);
        debugPrint("Editando pago. ID: ${updatedPago.id}");

        // Si el pago anterior estaba programado, cancela su notificación
        if (previousPago.estaProgramado) {
          debugPrint(
              "Cancelando notificación anterior para pago: ${previousPago.id}");
          await NotificationService().cancelRecurringNotification(
            _getNotificationId(previousPago.id),
          );
        }
      } else {
        debugPrint("El documento a editar no existe. ID: ${updatedPago.id}");
      }

      // Actualiza el pago en Firestore
      await docRef.update(updatedPago.toMap());

      // Si el pago actualizado es programado, programa su nueva notificación
      if (updatedPago.estaProgramado) {
        debugPrint(
            "Programando nueva notificación para pago editado: ${updatedPago.id}");
        // Programa la notificación pasando el objeto actualizado (que ya tiene el ID)
        await NotificationService().scheduleRecurringNotification(updatedPago);
      }
    } catch (e) {
      debugPrint("Error en editarPago: $e");
      rethrow;
    }
  }

  /// Elimina un pago de Firestore.
  /// Nota: La cancelación de notificaciones asociadas debería manejarse
  /// idealmente aquí también, pero el código original no lo hacía.
  /// Se podría agregar si se desea mayor robustez.
  Future<void> eliminarPago(String id) async {
    if (id.isEmpty) {
      throw Exception("No se puede eliminar un pago sin ID");
    }
    try {
      debugPrint("Eliminando pago con ID: $id");
      await _pagosCollection.doc(id).delete();
      // Opcional: Cancelar notificación asociada aquí si se desea
      // await NotificationService().cancelRecurringNotification(_getNotificationId(id));
    } catch (e) {
      debugPrint("Error al eliminar pago: $e");
      rethrow;
    }
  }

  /// (Función auxiliar) Genera el ID de notificación basado en el ID del pago.
  /// Se usa principalmente para cancelar notificaciones.
  int _getNotificationId(String pagoId) {
    return pagoId.hashCode % 1000000000;
  }
}
