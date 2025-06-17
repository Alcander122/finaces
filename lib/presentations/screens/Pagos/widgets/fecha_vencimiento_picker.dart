// Widget reusable para selección de fecha de vencimiento
import 'package:flutter/material.dart';

class FechaVencimientoPicker extends StatelessWidget {
  final DateTime fecha;
  final ValueChanged<DateTime> onChanged;

  const FechaVencimientoPicker({
    super.key,
    required this.fecha,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        "Fecha de vencimiento: ${fecha.toLocal().toString().split(' ')[0]}",
      ),
      trailing: IconButton(
        icon: const Icon(Icons.calendar_today),
        onPressed: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: fecha,
            firstDate: DateTime.now(),
            lastDate: DateTime(2100),
          );
          if (date != null) onChanged(date);
        },
      ),
    );
  }
}