import 'package:finances/core/data/models/objetivo_ahorro.dart';
import 'package:flutter/material.dart';

class ElementoObjetivoAhorro extends StatelessWidget {
  final ObjetivoAhorro meta;
  final Function(String) onTransaccion;
  final Function() onVerDetalles;

  const ElementoObjetivoAhorro({
    super.key,
    required this.meta,
    required this.onTransaccion,
    required this.onVerDetalles,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meta.nombre,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: meta.progreso / 100,
              minHeight: 10,
              color: Colors.green,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 10),
            Text(
              '\$${meta.montoActual.toStringAsFixed(2)} / \$${meta.montoObjetivo.toStringAsFixed(2)}',
            ),
            Text(meta.progreso >= 100
                ? '¡Meta cumplida!'
                : 'Progreso: ${meta.progreso.toStringAsFixed(1)}%'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.green),
                  onPressed: () => onTransaccion('deposito'),
                ),
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.red),
                  onPressed: () => onTransaccion('retiro'),
                ),
                IconButton(
                  icon: const Icon(Icons.description, color: Colors.blue),
                  onPressed: onVerDetalles,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
