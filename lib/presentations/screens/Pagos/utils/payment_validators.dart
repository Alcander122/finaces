import 'package:timezone/timezone.dart' as tz;
import '../models/payment_enums.dart';
import '../models/payment.dart';

class PaymentValidators {
  /// Verifica si la configuración de notificaciones es matemáticamente posible.
  /// (Ej: Retorna false si se pide un recordatorio de 7 días pero el pago vence mañana).
  static bool isNotificationOffsetValid(tz.TZDateTime? nextDueDate,
      List<int> notifyDaysBefore, tz.TZDateTime now) {
    if (nextDueDate == null) return true;

    for (int offset in notifyDaysBefore) {
      final scheduledDate = nextDueDate.subtract(Duration(days: offset));
      // Si la fecha programada ya pasó, la configuración es inválida o expirada.
      if (scheduledDate.isBefore(now)) {
        return false;
      }
    }
    return true;
  }

  /// Verifica si el pago ya sobrepasó su fecha límite basándose en la hora local actual.
  static bool isPaymentOverdue(Payment payment, tz.TZDateTime now) {
    if (payment.status == PaymentStatus.paid ||
        payment.status == PaymentStatus.paused) {
      return false;
    }

    // Si no hay fecha de vencimiento, no está vencido
    if (payment.nextDueDate == null) {
      return false;
    }

    // Ignoramos la hora para el cálculo de vencimiento estricto (vence cuando se acaba el día 23:59:59)
    final endOfDueDate = tz.TZDateTime(
      payment.nextDueDate!.location,
      payment.nextDueDate!.year,
      payment.nextDueDate!.month,
      payment.nextDueDate!.day,
      23,
      59,
      59,
    );

    return now.isAfter(endOfDueDate);
  }
}
