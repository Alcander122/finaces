import 'package:finances/core/data/models/objetivo_ahorro.dart';
import 'package:flutter/material.dart';

class ElementoObjetivoAhorro extends StatelessWidget {
  final ObjetivoAhorro meta;
  final Function(String) onTransaccion;

  const ElementoObjetivoAhorro({
    super.key,
    required this.meta,
    required this.onTransaccion,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(meta.nombre, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: meta.progreso / 100,
              minHeight: 10,
              color: Colors.green,
            ),
            const SizedBox(height: 10),
            Text(
                '\$${meta.montoActual.toStringAsFixed(2)} / \$${meta.montoObjetivo.toStringAsFixed(2)}'),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
