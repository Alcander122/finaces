import 'package:timezone/timezone.dart' as tz;
import '../models/payment_enums.dart';
import '../models/payment.dart';

class NotificationDateUtils {
  /// Devuelve una lista de las fechas exactas en las que debe dispararse un push,
  /// basado en los offsets configurados y la hora de notificación elegida.
  static List<tz.TZDateTime> calculateNotificationSchedules(Payment payment) {
    if (payment.notifyDaysBefore.isEmpty ||
        payment.status != PaymentStatus.pending) {
      return [];
    }

    final dueDate = payment.nextDueDate;

    // Si no hay fecha de vencimiento, no hay notificaciones que calcular
    if (dueDate == null) {
      return [];
    }

    final timeOfDay = payment.notificationTimeOfDay;

    List<tz.TZDateTime> schedules = [];

    for (int daysBefore in payment.notifyDaysBefore) {
      // Restamos los días exactos al due date
      tz.TZDateTime scheduleDay = dueDate.subtract(Duration(days: daysBefore));

      // Si el usuario configuró una hora específica, aplicarla. Si no, default a 09:00 AM.
      int targetHour = timeOfDay != null ? timeOfDay.hour : 9;
      int targetMinute = timeOfDay != null ? timeOfDay.minute : 0;

      scheduleDay = tz.TZDateTime(
        scheduleDay.location,
        scheduleDay.year,
        scheduleDay.month,
        scheduleDay.day,
        targetHour,
        targetMinute,
      );

      schedules.add(scheduleDay);
    }

    return schedules;
  }
}
