// Widget reusable para selección de fecha de vencimiento
import 'package:flutter/material.dart';

class FechaVencimientoPicker extends StatelessWidget {
  final DateTime? fecha;
  final ValueChanged<DateTime> onChanged;

  const FechaVencimientoPicker({
    super.key,
    required this.fecha,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fechaMostrada = fecha ?? DateTime.now();

    return ListTile(
      title: Text(
        "Fecha de vencimiento: ${fechaMostrada.toLocal().toString().split(' ')[0]}",
      ),
      trailing: IconButton(
        icon: const Icon(Icons.calendar_today),
        onPressed: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: fechaMostrada,
            firstDate: DateTime.now(),
            lastDate: DateTime(2100),
          );
          if (date != null) onChanged(date);
        },
      ),
    );
  }
}
