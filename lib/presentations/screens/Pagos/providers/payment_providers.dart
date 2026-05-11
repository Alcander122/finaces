import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/payment_repository.dart';
import '../models/payment.dart';

// Repositorio
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(firestore: FirebaseFirestore.instance);
});

// Stream de pagos
final paymentsStreamProvider =
    StreamProvider.family<List<Payment>, String>((ref, userId) {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.streamPayments(userId);
});

// Controlador para mutaciones
class PaymentController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is void
  }

  Future<void> createPayment(Payment payment) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final repository = ref.read(paymentRepositoryProvider);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }
      await repository.createPayment(payment.copyWith(userId: user.uid));
    });
    state = result;
    if (result.hasError) {
      throw result.error!;
    }
  }

  Future<void> updatePayment(Payment payment) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(paymentRepositoryProvider);
      await repository.updatePayment(payment);
    });
  }

  Future<void> deletePayment(String userId, String paymentId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(paymentRepositoryProvider);
      await repository.deletePayment(userId, paymentId);
    });
  }
}

final paymentControllerProvider =
    AsyncNotifierProvider<PaymentController, void>(() {
  return PaymentController();
});
