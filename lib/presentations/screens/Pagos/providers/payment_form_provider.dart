import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../models/payment.dart';
import '../models/payment_enums.dart';
import '../models/recurrence.dart';
import '../utils/notification_date_utils.dart';
import '../utils/next_due_date_calculator.dart';

final paymentFormProvider = NotifierProvider<PaymentFormNotifier, Payment>(() {
  return PaymentFormNotifier();
});

class PaymentFormNotifier extends Notifier<Payment> {
  @override
  Payment build() {
    final now = tz.TZDateTime.now(tz.local);
    final initialDueDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 23, 59);

    return Payment(
      id: const Uuid().v4(),
      userId: '',
      title: 'Nuevo Pago',
      totalAmount: 0.0,
      nextDueDate: initialDueDate,
      recurrence: const Recurrence(),
      notifyDaysBefore: [1],
      notificationTimeOfDay:
          tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0),
      status: PaymentStatus.pending,
    );
  }

  void updateFrequency(FrequencyUnit unit) {
    int defaultInterval = (unit == FrequencyUnit.none) ? 0 : 1;
    state = state.copyWith(
      recurrence:
          state.recurrence.copyWith(unit: unit, interval: defaultInterval),
    );
  }

  void setNextDueDate(tz.TZDateTime date) {
    state = state.copyWith(nextDueDate: date);
  }

  void toggleNotificationOffset(int daysBefore) {
    final currentList = List<int>.from(state.notifyDaysBefore);
    if (currentList.contains(daysBefore)) {
      currentList.remove(daysBefore);
    } else {
      currentList.add(daysBefore);
    }
    state = state.copyWith(notifyDaysBefore: currentList);
  }

  void updateNotificationTime(tz.TZDateTime time) {
    state = state.copyWith(notificationTimeOfDay: time);
  }

  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  void updateTotalAmount(double amount) {
    state = state.copyWith(totalAmount: amount);
  }

  void setStatus(PaymentStatus status) {
    state = state.copyWith(status: status);
  }

  void loadPayment(Payment payment) {
    state = payment;
  }
}

final paymentPreviewProvider = Provider.autoDispose<List<tz.TZDateTime>>((ref) {
  final draft = ref.watch(paymentFormProvider);
  // Usar el próximo vencimiento futuro calculado en lugar de la fecha base
  final nextDueDate = NextDueDateCalculator.calculateNextFutureDate(draft);

  // Recalcular con el próximo vencimiento real
  final draftWithNextDue = draft.copyWith(nextDueDate: nextDueDate);
  return NotificationDateUtils.calculateNotificationSchedules(draftWithNextDue);
});

final invalidNotificationOffsetsProvider =
    Provider.autoDispose<List<int>>((ref) {
  final draft = ref.watch(paymentFormProvider);
  final now = tz.TZDateTime.now(tz.local);

  // Si no hay fecha de vencimiento, no hay offsets inválidos
  if (draft.nextDueDate == null) {
    return [];
  }

  // No permitir offsets que ya pasaron hace más de 24 horas atrás
  final possibleOffsets = [0, 1, 2, 3, 5, 7, 15, 30];
  final List<int> invalidOffsets = [];

  for (int offset in possibleOffsets) {
    final scheduledDate = draft.nextDueDate!.subtract(Duration(days: offset));

    // Solo marcar como inválido si la notificación sería hace más de 24 horas
    final oneDayAgo = now.subtract(const Duration(days: 1));
    if (scheduledDate.isBefore(oneDayAgo)) {
      invalidOffsets.add(offset);
    }
  }

  return invalidOffsets;
});
