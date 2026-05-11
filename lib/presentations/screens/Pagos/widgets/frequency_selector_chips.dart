import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_enums.dart';
import '../providers/payment_form_provider.dart';

class FrequencySelectorChips extends ConsumerWidget {
  const FrequencySelectorChips({super.key});

  String _getLabel(FrequencyUnit unit) {
    switch (unit) {
      case FrequencyUnit.none: return 'Único';
      case FrequencyUnit.days: return 'Diario';
      case FrequencyUnit.weeks: return 'Semanal';
      case FrequencyUnit.months: return 'Mensual';
      case FrequencyUnit.years: return 'Anual';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUnit = ref.watch(paymentFormProvider.select((p) => p.recurrence.unit));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frecuencia del Pago', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: [FrequencyUnit.none, FrequencyUnit.weeks, FrequencyUnit.months, FrequencyUnit.years]
              .map((unit) {
            return ChoiceChip(
              label: Text(_getLabel(unit)),
              selected: currentUnit == unit,
              onSelected: (selected) {
                if (selected) {
                  ref.read(paymentFormProvider.notifier).updateFrequency(unit);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
