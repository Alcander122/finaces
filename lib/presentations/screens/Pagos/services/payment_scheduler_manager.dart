import 'dart:developer' as developer;
import 'package:timezone/timezone.dart' as tz;
import 'package:finances/core/data/utils/ui_helpers.dart';
import '../models/payment.dart';
import '../models/payment_enums.dart';
import '../utils/notification_id_generator.dart';
import '../utils/notification_date_utils.dart';
import 'notification_service.dart';

class PaymentSchedulerManager {
  final NotificationService _notificationService;

  PaymentSchedulerManager(this._notificationService);

  /// Cancela y reprograma todas las notificaciones pendientes de un pago.
  /// Debe llamarse después de que el pago se haya guardado en Firestore.
  Future<void> syncPaymentNotifications(Payment payment) async {
    developer.log('Iniciando sync para: ${payment.id}', name: 'PaymentSchedulerManager');
    
    // 1. Cancelar alarmas anteriores (asegura no duplicar)
    await cancelPaymentNotifications(payment);

    if (payment.status != PaymentStatus.pending) {
      developer.log('Pago no está pendiente, se omiten alarmas.', name: 'PaymentSchedulerManager');
      return;
    }

    // 2. Calcular los nuevos horarios
    final schedules = NotificationDateUtils.calculateNotificationSchedules(payment);
    final now = tz.TZDateTime.now(tz.local);

    // 3. Encolar nuevas notificaciones
    for (int i = 0; i < schedules.length; i++) {
      final scheduledDate = schedules[i];
      final offset = payment.notifyDaysBefore[i];
      
      // Evitar programar fechas pasadas
      if (scheduledDate.isBefore(now)) {
        developer.log('Omitiendo notificación de hace $offset días (fecha pasada).', name: 'PaymentSchedulerManager');
        continue;
      }

      final int notificationId = NotificationIdGenerator.generateDeterministicId(payment.id, offset);
      
      String body = 'Tu pago "${payment.title}" de ${UIHelpers.formatCurrency(payment.totalAmount)} vence ';
      if (offset == 0) {
        body += 'hoy.';
      } else if (offset == 1) {
        body += 'mañana.';
      } else {
        body += 'en $offset días.';
      }

      await _notificationService.scheduleNotification(
        id: notificationId,
        title: 'Recordatorio de Pago',
        body: body,
        scheduledDate: scheduledDate,
        payload: payment.id,
      );
    }
  }

  /// Cancela proactivamente todas las notificaciones posibles de un pago.
  Future<void> cancelPaymentNotifications(Payment payment) async {
    // Si el usuario borró un offset, el ID huérfano podría quedar si no persistimos los offsets previos.
    // Borramos IDs de offsets comunes para "limpiar".
    final possibleOffsets = [0, 1, 2, 3, 5, 7, 15, 30];
    for (int offset in possibleOffsets) {
      final int notificationId = NotificationIdGenerator.generateDeterministicId(payment.id, offset);
      await _notificationService.cancelNotification(notificationId);
    }
    developer.log('Limpieza de offsets completada para: ${payment.id}', name: 'PaymentSchedulerManager');
  }
}
