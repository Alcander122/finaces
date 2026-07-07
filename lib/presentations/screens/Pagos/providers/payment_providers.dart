import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/errors/handlers/db_error_handler.dart';
import '../repositories/payment_repository.dart';
import '../models/payment.dart';
import '../models/payment_enums.dart';
import '../services/payment_scheduler_manager.dart';
import '../services/notification_service.dart';
import '../utils/recurrence_calculator.dart';

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

// Scheduler Provider
final paymentSchedulerProvider = Provider<PaymentSchedulerManager>((ref) {
  return PaymentSchedulerManager(NotificationService());
});

// Modelo de Estadísticas para KPIs
class PaymentStats {
  final double pendingMonth;
  final double paidMonth;
  final double overdueTotal;
  final int upcomingCount;

  const PaymentStats({
    this.pendingMonth = 0.0,
    this.paidMonth = 0.0,
    this.overdueTotal = 0.0,
    this.upcomingCount = 0,
  });
}

// Provider de Estadísticas de Pagos
final paymentStatsProvider = Provider.family<PaymentStats, String>((ref, userId) {
  final paymentsAsync = ref.watch(paymentsStreamProvider(userId));
  
  return paymentsAsync.maybeWhen(
    data: (payments) {
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      double pendingMonth = 0.0;
      double paidMonth = 0.0;
      double overdueTotal = 0.0;
      int upcomingCount = 0;

      for (final p in payments) {
        final due = p.nextDueDate;
        if (due == null) continue;

        // Comprobar si el vencimiento es en el mes corriente
        final isCurrentMonth = due.month == currentMonth && due.year == currentYear;
        
        // Comprobar si está vencido (fecha en el pasado y no pagado)
        // Damos un margen de tolerancia (ej. final del día de vencimiento)
        final todayStart = DateTime(now.year, now.month, now.day);
        final dueStart = DateTime(due.year, due.month, due.day);
        final isPast = dueStart.isBefore(todayStart);

        if (p.status == PaymentStatus.paid) {
          if (isCurrentMonth) {
            paidMonth += p.totalAmount;
          }
        } else if (p.status == PaymentStatus.pending) {
          if (isCurrentMonth) {
            pendingMonth += p.totalAmount;
          }
          if (isPast) {
            overdueTotal += p.totalAmount;
          }

          // Próximos vencimientos en los próximos 7 días (incluido hoy)
          final differenceDays = dueStart.difference(todayStart).inDays;
          if (differenceDays >= 0 && differenceDays <= 7) {
            upcomingCount++;
          }
        }
      }

      return PaymentStats(
        pendingMonth: pendingMonth,
        paidMonth: paidMonth,
        overdueTotal: overdueTotal,
        upcomingCount: upcomingCount,
      );
    },
    orElse: () => const PaymentStats(),
  );
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
      final paymentWithUser = payment.copyWith(userId: user.uid);
      final createdId = await repository.createPayment(paymentWithUser);
      final finalPayment = paymentWithUser.copyWith(id: createdId);
      
      // Sincronizar las alarmas de este pago con el ID real de Firestore
      await ref.read(paymentSchedulerProvider).syncPaymentNotifications(finalPayment);
    });
    
    if (result.hasError) {
      final cleanedError = DbErrorHandler.handle(result.error);
      state = AsyncValue.error(cleanedError, StackTrace.current);
      throw cleanedError;
    } else {
      state = result;
    }
  }

  Future<void> updatePayment(Payment payment) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final repository = ref.read(paymentRepositoryProvider);
      await repository.updatePayment(payment);
      
      // Cancelar y reprogramar alarmas
      await ref.read(paymentSchedulerProvider).syncPaymentNotifications(payment);
    });

    if (result.hasError) {
      final cleanedError = DbErrorHandler.handle(result.error);
      state = AsyncValue.error(cleanedError, StackTrace.current);
      throw cleanedError;
    } else {
      state = result;
    }
  }

  Future<void> deletePayment(String userId, String paymentId) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final repository = ref.read(paymentRepositoryProvider);
      // Cancelar notificaciones activas del pago antes de eliminarlo
      final dummyPayment = Payment(id: paymentId, userId: userId);
      await ref.read(paymentSchedulerProvider).cancelPaymentNotifications(dummyPayment);
      
      await repository.deletePayment(userId, paymentId);
    });

    if (result.hasError) {
      final cleanedError = DbErrorHandler.handle(result.error);
      state = AsyncValue.error(cleanedError, StackTrace.current);
      throw cleanedError;
    } else {
      state = result;
    }
  }

  Future<void> payPayment(Payment payment) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final repository = ref.read(paymentRepositoryProvider);
      final scheduler = ref.read(paymentSchedulerProvider);

      if (payment.recurrence.unit != FrequencyUnit.none) {
        // Si es recurrente, calculamos el siguiente estado del pago (nueva fecha de vencimiento)
        final nextPayment = RecurrenceCalculator.calculateNextPaymentState(payment);
        await repository.updatePayment(nextPayment);
        // Sincronizamos las alarmas para el nuevo periodo
        await scheduler.syncPaymentNotifications(nextPayment);
      } else {
        // Si es pago único, lo marcamos como pagado
        final paidPayment = payment.copyWith(status: PaymentStatus.paid);
        await repository.updatePayment(paidPayment);
        // Cancelamos las alarmas asociadas
        await scheduler.cancelPaymentNotifications(paidPayment);
      }
    });

    if (result.hasError) {
      final cleanedError = DbErrorHandler.handle(result.error);
      state = AsyncValue.error(cleanedError, StackTrace.current);
      throw cleanedError;
    } else {
      state = result;
    }
  }
}

final paymentControllerProvider =
    AsyncNotifierProvider<PaymentController, void>(() {
  return PaymentController();
});
