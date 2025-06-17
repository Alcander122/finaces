// BottomSheet para selección de días antes del vencimiento
import 'package:flutter/material.dart';

class DiasAntesBottomSheet extends StatelessWidget {
  final ValueChanged<int> onDiasSeleccionados;

  const DiasAntesBottomSheet({
    super.key,
    required this.onDiasSeleccionados,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Selecciona los días antes del vencimiento:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('1 día'),
            onTap: () {
              Navigator.pop(context);
              onDiasSeleccionados(1);
            },
          ),
          ListTile(
            title: const Text('3 días'),
            onTap: () {
              Navigator.pop(context);
              onDiasSeleccionados(3);
            },
          ),
          ListTile(
            title: const Text('7 días'),
            onTap: () {
              Navigator.pop(context);
              onDiasSeleccionados(7);
            },
          ),
        ],
      ),
    );
  }
}