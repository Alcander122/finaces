import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/scheduled_payment_repository.dart';
import '../../data/scheduled_payment_model.dart';
import '../../services/advanced_notification_service.dart';

// Repositorio
final scheduledPaymentRepoProvider = Provider((ref) => ScheduledPaymentRepository());

// Servicio de Notificaciones
final notificationServiceProvider = Provider((ref) => AdvancedNotificationService());

// StreamProvider para la UI (Muestra la lista en tiempo real)
final paymentsStreamProvider = StreamProvider<List<ScheduledPayment>>((ref) {
  final repo = ref.watch(scheduledPaymentRepoProvider);
  return repo.getPaymentsStream();
});

// Provider del Controlador (Maneja la lógica de negocio)
final paymentControllerProvider = Provider((ref) {
  return PaymentController(
    ref.watch(scheduledPaymentRepoProvider),
    ref.watch(notificationServiceProvider),
  );
});

class PaymentController {
  final ScheduledPaymentRepository _repo;
  final AdvancedNotificationService _notificationService;

  PaymentController(this._repo, this._notificationService);

  /// Crea un nuevo pago programado en Firestore y agenda sus notificaciones
  Future<void> createScheduledPayment({
    required String title,
    required double amount,
    required DateTime dueDate,
    required String frequency,
    required List<int> reminders,
  }) async {
    try {
      // Generamos un ID base determinístico para las notificaciones (Timestamp en segundos)
      final int baseNotificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final payment = ScheduledPayment(
        id: '', // Firestore generará el ID del documento
        title: title,
        amount: amount,
        dueDate: dueDate,
        frequency: frequency,
        reminders: reminders,
        baseNotificationId: baseNotificationId,
      );

      // 1. Guardar en Firestore
      final docId = await _repo.addPayment(payment);

      // 2. Crear instancia con el ID real de Firestore
      final savedPayment = ScheduledPayment(
        id: docId,
        title: title,
        amount: amount,
        dueDate: dueDate,
        frequency: frequency,
        reminders: reminders,
        baseNotificationId: baseNotificationId,
      );
      
      // 3. Programar Alarmas
      await _notificationService.scheduleMultipleReminders(savedPayment);
    } catch (e) {
      throw Exception('Error al guardar el pago: $e');
    }
  }

  /// Actualiza un pago existente. Cancela las alarmas viejas y reprograma.
  Future<void> updateScheduledPayment(ScheduledPayment updatedPayment) async {
    try {
      // 1. Actualizamos Firestore
      await _repo.updatePayment(updatedPayment);

      // 2. Reprogramar alarmas si no está pagado (si se edita para pagado, no suenan)
      if (!updatedPayment.isPaid) {
        await _notificationService.scheduleMultipleReminders(updatedPayment);
      } else {
        await _notificationService.cancelPaymentReminders(updatedPayment);
      }
    } catch (e) {
      throw Exception('Error al actualizar el pago: $e');
    }
  }

  /// Marca un pago como completado. Si es recurrente, lo reprograma para la siguiente fecha.
  Future<void> markAsPaid(ScheduledPayment payment) async {
    try {
      // 1. Cancelar alarmas del ciclo actual
      await _notificationService.cancelPaymentReminders(payment);

      if (payment.frequency == 'none') {
        // Pago único: simplemente lo marcamos como pagado
        final paidPayment = ScheduledPayment(
          id: payment.id,
          title: payment.title,
          amount: payment.amount,
          dueDate: payment.dueDate,
          frequency: payment.frequency,
          reminders: payment.reminders,
          baseNotificationId: payment.baseNotificationId,
          isPaid: true,
        );
        await _repo.updatePayment(paidPayment);
      } else {
        // Pago recurrente: Avanzar la fecha al próximo ciclo y dejar isPaid=false
        DateTime nextDueDate;
        switch (payment.frequency) {
          case 'weekly':
            nextDueDate = payment.dueDate.add(const Duration(days: 7));
            break;
          case 'monthly':
            // Sumar 1 mes conservando el mismo día (cuidado con 31 de Febrero, etc. DateTime maneja el overflow)
            nextDueDate = DateTime(
              payment.dueDate.year,
              payment.dueDate.month + 1,
              payment.dueDate.day,
              payment.dueDate.hour,
              payment.dueDate.minute,
            );
            break;
          case 'yearly':
            nextDueDate = DateTime(
              payment.dueDate.year + 1,
              payment.dueDate.month,
              payment.dueDate.day,
              payment.dueDate.hour,
              payment.dueDate.minute,
            );
            break;
          default:
            nextDueDate = payment.dueDate;
        }

        final nextPayment = ScheduledPayment(
          id: payment.id,
          title: payment.title,
          amount: payment.amount,
          dueDate: nextDueDate, // Nueva fecha
          frequency: payment.frequency,
          reminders: payment.reminders,
          baseNotificationId: payment.baseNotificationId,
          isPaid: false, // Vuelve a estar pendiente
        );

        await _repo.updatePayment(nextPayment);
        await _notificationService.scheduleMultipleReminders(nextPayment);
      }
    } catch (e) {
      throw Exception('Error al procesar el pago: $e');
    }
  }

  /// Elimina el pago de Firestore y cancela todas sus alarmas
  Future<void> deletePayment(ScheduledPayment payment) async {
    try {
      // 1. Cancelar alarmas
      await _notificationService.cancelPaymentReminders(payment);
      // 2. Borrar de base de datos
      await _repo.deletePayment(payment.id);
    } catch (e) {
      throw Exception('Error al eliminar el pago: $e');
    }
  }
}
