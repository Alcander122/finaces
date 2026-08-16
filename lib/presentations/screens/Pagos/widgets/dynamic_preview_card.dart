import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/payment_form_provider.dart';
import '../utils/next_due_date_calculator.dart';

class DynamicPreviewCard extends ConsumerWidget {
  const DynamicPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(paymentFormProvider);
    final upcomingReminders = ref.watch(paymentPreviewProvider);

    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: Colors.blue.withValues(alpha: isDark ? 0.12 : 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: Colors.blue.withValues(alpha: isDark ? 0.35 : 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome,
                    color: isDark ? Colors.blue[300] : Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text('Previsualización',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? Colors.blue[300] : Colors.blue[800])),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text('Próximo Vencimiento:',
                style: Theme.of(context).textTheme.bodySmall),
            Text(
              draft.nextDueDate != null
                  ? dateFormat
                      .format(NextDueDateCalculator.calculateNextFutureDate(draft))
                  : 'No definido',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Recordatorios Programados:',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            if (upcomingReminders.isEmpty)
              const Text('Sin alertas programadas',
                  style: TextStyle(
                      color: Colors.grey, fontStyle: FontStyle.italic)),
            ...upcomingReminders.map((date) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active,
                          size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text(
                          '${dateFormat.format(date)} - ${timeFormat.format(date)}',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
