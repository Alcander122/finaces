// BottomSheet para selección de frecuencia de pago
import 'package:flutter/material.dart';

class FrecuenciaBottomSheet extends StatelessWidget {
  final ValueChanged<String> onFrecuenciaSeleccionada;

  const FrecuenciaBottomSheet({
    super.key,
    required this.onFrecuenciaSeleccionada,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Selecciona la frecuencia de recurrencia:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Mensual'),
            onTap: () {
              Navigator.pop(context);
              onFrecuenciaSeleccionada('mensual');
            },
          ),
          ListTile(
            title: const Text('Semanal'),
            onTap: () {
              Navigator.pop(context);
              onFrecuenciaSeleccionada('semanal');
            },
          ),
          ListTile(
            title: const Text('Anual'),
            onTap: () {
              Navigator.pop(context);
              onFrecuenciaSeleccionada('anual');
            },
          ),
        ],
      ),
    );
  }
}