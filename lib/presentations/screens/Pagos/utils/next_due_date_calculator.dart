import 'package:timezone/timezone.dart' as tz;
import '../models/payment.dart';
import '../models/payment_enums.dart';
import 'due_date_utils.dart';

/// Calcula el próximo vencimiento real basándose en la fecha base y la recurrencia.
/// Si el pago no es recurrente, devuelve la fecha de vencimiento configurada.
class NextDueDateCalculator {
  static tz.TZDateTime calculateNextDueDate(Payment payment) {
    final baseDate = payment.nextDueDate;
    if (baseDate == null) {
      return tz.TZDateTime.now(tz.local);
    }

    // Si no es recurrente, retornar la fecha base
    if (payment.recurrence.unit == FrequencyUnit.none) {
      return baseDate;
    }

    // Si es recurrente, calcular basándose en el intervalo y la cuota actual
    final interval = payment.recurrence.interval;
    final currentInstallment = payment.recurrence.currentInstallment;

    // Si no se ha iniciado ninguna cuota, asumimos que la siguiente fecha es la primera siguiente
    final effectiveInstallment =
        (currentInstallment == null || currentInstallment <= 0)
            ? 1
            : currentInstallment;

    tz.TZDateTime nextDate = baseDate;

    // Aplicar el intervalo según la frecuencia
    switch (payment.recurrence.unit) {
      case FrequencyUnit.days:
        nextDate =
            baseDate.add(Duration(days: interval * effectiveInstallment));
        break;

      case FrequencyUnit.weeks:
        nextDate =
            baseDate.add(Duration(days: interval * 7 * effectiveInstallment));
        break;

      case FrequencyUnit.semiMonthly:
        nextDate = _calculateNextSemiMonthly(baseDate, interval * effectiveInstallment);
        break;

      case FrequencyUnit.months:
        nextDate = DueDateUtils.addMonthsWithSnapToEnd(
            baseDate, interval * effectiveInstallment);
        break;

      case FrequencyUnit.years:
        nextDate = DueDateUtils.addMonthsWithSnapToEnd(
            baseDate, interval * 12 * effectiveInstallment);
        break;

      case FrequencyUnit.none:
        // Ya manejado arriba
        break;
    }

    return nextDate;
  }

  static tz.TZDateTime _calculateNextSemiMonthly(tz.TZDateTime date, int steps) {
    tz.TZDateTime current = date;
    for (int i = 0; i < steps; i++) {
      int year = current.year;
      int month = current.month;
      int day = current.day;

      int newYear = year;
      int newMonth = month;
      int newDay;

      final lastDayOfCurrentMonth = DueDateUtils.daysInMonth(year, month);

      if (day < 15) {
        newDay = 15;
      } else if (day < lastDayOfCurrentMonth) {
        newDay = lastDayOfCurrentMonth;
      } else {
        // Avanzar al 15 del mes siguiente
        newMonth = month + 1;
        if (newMonth > 12) {
          newYear++;
          newMonth = 1;
        }
        newDay = 15;
      }
      current = tz.TZDateTime(current.location, newYear, newMonth, newDay, current.hour, current.minute, current.second);
    }
    return current;
  }
}
