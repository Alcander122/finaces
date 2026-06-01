import 'package:timezone/timezone.dart' as tz;
import '../models/payment_enums.dart';
import '../models/payment.dart';
import 'due_date_utils.dart';
import 'next_due_date_calculator.dart';

class RecurrenceCalculator {
  /// Calcula el siguiente estado del pago (fecha y cuota) después de pagarse.
  /// Lanza una excepción si el pago no es recurrente o ya terminó sus cuotas.
  static Payment calculateNextPaymentState(Payment currentPayment) {
    if (currentPayment.recurrence.unit == FrequencyUnit.none) {
      throw Exception("El pago no es recurrente.");
    }

    if (currentPayment.nextDueDate == null) {
      throw Exception("El pago no tiene fecha de vencimiento definida.");
    }

    final recurrence = currentPayment.recurrence;

    // Si hay cuotas límite y ya se llegó a la final, el pago se marca como 'pagado' permanentemente.
    if (recurrence.totalInstallments != null &&
        recurrence.currentInstallment != null) {
      if (recurrence.currentInstallment! >= recurrence.totalInstallments!) {
        return currentPayment.copyWith(status: PaymentStatus.paid);
      }
    }

    // Recalcular siempre sobre el nextDueDate ORIGINAL (evita el drift temporal)
    final tz.TZDateTime oldDate = currentPayment.nextDueDate!;
    tz.TZDateTime newDate;

    switch (recurrence.unit) {
      case FrequencyUnit.days:
        newDate = oldDate.add(Duration(days: recurrence.interval));
        break;
      case FrequencyUnit.weeks:
        newDate = oldDate.add(Duration(days: recurrence.interval * 7));
        break;
      case FrequencyUnit.semiMonthly:
        newDate = NextDueDateCalculator.calculateNextDueDate(currentPayment);
        break;
      case FrequencyUnit.months:
        newDate =
            DueDateUtils.addMonthsWithSnapToEnd(oldDate, recurrence.interval);
        break;
      case FrequencyUnit.years:
        newDate = DueDateUtils.addMonthsWithSnapToEnd(
            oldDate, recurrence.interval * 12);
        break;
      default:
        newDate = oldDate;
    }

    int? nextInstallment = recurrence.currentInstallment;
    if (nextInstallment != null) {
      nextInstallment++;
    }

    return currentPayment.copyWith(
      nextDueDate: newDate,
      status: PaymentStatus.pending,
      paidAmount: 0.0, // Se resetea la deuda
      recurrence: recurrence.copyWith(currentInstallment: nextInstallment),
    );
  }
}
