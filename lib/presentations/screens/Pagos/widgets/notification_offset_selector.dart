import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/payment_form_provider.dart';

class NotificationOffsetSelector extends ConsumerWidget {
  const NotificationOffsetSelector({super.key});

  String _getLabel(int offset) {
    if (offset == 0) return 'Mismo día';
    if (offset == 1) return '1 día antes';
    return '$offset días antes';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedOffsets =
        ref.watch(paymentFormProvider.select((p) => p.notifyDaysBefore));

    final options = [0, 1, 3, 7, 15];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¿Cuándo te avisamos?',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: options.map((offset) {
            final isSelected = selectedOffsets.contains(offset);

            return FilterChip(
              label: Text(_getLabel(offset)),
              selected: isSelected,
              onSelected: (bool value) {
                ref
                    .read(paymentFormProvider.notifier)
                    .toggleNotificationOffset(offset);
              },
              selectedColor:
                  Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.black87,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
