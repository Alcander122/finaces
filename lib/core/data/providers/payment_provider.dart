// payment_provider.dart
import 'dart:async';
import 'package:finances/core/data/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/pago_model.dart';

final paymentProvider = StateNotifierProvider.family<PaymentNotifier,
    AsyncValue<List<Pago>>, String>((ref, userId) {
  return PaymentNotifier(userId);
});

class PaymentNotifier extends StateNotifier<AsyncValue<List<Pago>>> {
  final String userId;
  StreamSubscription<QuerySnapshot>? _subscription;

  CollectionReference get _pagosCollection => FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('pagos');

  PaymentNotifier(this.userId) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      if (userId.isEmpty) {
        state = AsyncValue.error(
            "User ID no puede estar vacío", StackTrace.current);
        return;
      }
      _subscription = _pagosCollection.snapshots().listen((snapshot) {
        final pagos = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return Pago(
            id: doc.id,
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

  // Agrega un nuevo pago
  Future<void> agregarPago(Pago pago) async {
    try {
      final docRef = await _pagosCollection.add(pago.toMap());

      if (pago.estaProgramado) {
        final notificationId = docRef.id.hashCode % 1000000000;
        final scheduledDate = pago.fechaVencimiento
            .subtract(Duration(days: pago.notificacionAntes));

        await NotificationService().scheduleRecurringNotification(
          pago.copyWith(id: docRef.id),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Edita un pago existente
  Future<void> editarPago(Pago updatedPago) async {
    try {
      final DocumentReference docRef = _pagosCollection.doc(updatedPago.id);
      final DocumentSnapshot snapshot = await docRef.get();

      if (snapshot.exists) {
        final previousPago =
            Pago.fromMap(snapshot.data() as Map<String, dynamic>);
        if (previousPago.estaProgramado) {
          final notificationId = previousPago.id.hashCode % 1000000000;
          await NotificationService().cancelRecurringNotification(
              previousPago.id.hashCode % 1000000000);
        }
      }

      await docRef.update(updatedPago.toMap());

      if (updatedPago.estaProgramado) {
        final notificationId = updatedPago.id.hashCode % 1000000000;
        final scheduledDate = updatedPago.fechaVencimiento
            .subtract(Duration(days: updatedPago.notificacionAntes));

        await NotificationService().scheduleRecurringNotification(
          updatedPago,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Elimina un pago
  Future<void> eliminarPago(String id) async {
    if (id.isEmpty) {
      throw Exception("No se puede eliminar un pago sin ID");
    }
    try {
      await _pagosCollection.doc(id).delete();
    } catch (e) {
      debugPrint("Error al eliminar pago: $e");
      rethrow;
    }
  }
}
