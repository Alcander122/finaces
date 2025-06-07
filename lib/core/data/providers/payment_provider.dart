import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/pago_model.dart';

// Proveedor de estado para los pagos

final paymentProvider = StateNotifierProvider.family<PaymentNotifier, AsyncValue<List<Pago>>, String>((ref, userId) {
  return PaymentNotifier(userId);
});

class PaymentNotifier extends StateNotifier<AsyncValue<List<Pago>>> {
  final String userId;
  StreamSubscription<QuerySnapshot>? _subscription;

  // Getter para la colección de pagos
  CollectionReference get _pagosCollection => FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('pagos');
  
  PaymentNotifier(this.userId) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      // IMPORTANTE: Verificar que userId no esté vacío
      if (userId.isEmpty) {
        state = AsyncValue.error("User ID no puede estar vacío", StackTrace.current);
        return;
      }
      
      final pagosCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('pagos');

      print("Iniciando listener para: users/$userId/pagos");

      // Usar .snapshots() para recibir actualizaciones en tiempo real
      _subscription = pagosCollection.snapshots().listen((snapshot) {
        final pagos = snapshot.docs.map((doc) {
          final data = doc.data();
          return Pago(
            id: doc.id,
            descripcion: data['descripcion'] ?? '',
            monto: (data['monto'] as num).toDouble(),
            fechaVencimiento: (data['fechaVencimiento'] as Timestamp).toDate(),
            estaProgramado: data['estaProgramado'] ?? false,
          );
        }).toList();
        
        print("Datos recibidos: ${pagos.length} pagos");
        state = AsyncValue.data(pagos);
      }, onError: (e) {
        print("Error en listener: $e");
        state = AsyncValue.error(e, StackTrace.current);
      });
    } catch (e, st) {
      print("Error en _init: $e");
      state = AsyncValue.error(e, st);
    }
  }

  // CANCELAR SUSCRIPCIÓN AL DESTRUIR
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> agregarPago(Pago pago) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('pagos');
      
      await docRef.add({
        'descripcion': pago.descripcion,
        'monto': pago.monto,
        'fechaVencimiento': pago.fechaVencimiento,
        'estaProgramado': pago.estaProgramado,
      });
      print("Pago agregado: ${pago.descripcion}");
    } catch (e) {
      print("Error agregando pago: $e");
      rethrow;
    }
  }

  // Editar pago existente
  Future<void> editarPago(Pago updatedPago) async {
    try {
      await _pagosCollection.doc(updatedPago.id).update(updatedPago.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Eliminar pago
  Future<void> eliminarPago(String id) async {
    try {
      await _pagosCollection.doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
}