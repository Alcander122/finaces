import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../providers/payment_form_provider.dart';

class NotificationTimeSelector extends ConsumerWidget {
  const NotificationTimeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationTime =
        ref.watch(paymentFormProvider.select((p) => p.notificationTimeOfDay));

    final hour = notificationTime?.hour ?? 9;
    final minute = notificationTime?.minute ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hora de notificación',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: hour, minute: minute),
                  );

                  if (picked != null) {
                    final now = tz.TZDateTime.now(tz.local);
                    final selectedTime = tz.TZDateTime(
                      tz.local,
                      now.year,
                      now.month,
                      now.day,
                      picked.hour,
                      picked.minute,
                    );

                    ref
                        .read(paymentFormProvider.notifier)
                        .updateNotificationTime(selectedTime);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
