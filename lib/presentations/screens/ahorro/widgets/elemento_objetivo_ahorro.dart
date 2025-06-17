import 'package:finances/core/data/models/objetivo_ahorro.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final theme = Theme.of(context);
    final formatoMoneda = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                meta.nombre,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: meta.progreso / 100,
              minHeight: 12,
              color: Colors.green,
              backgroundColor: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatoMoneda.format(meta.montoActual),
                  style: theme.textTheme.bodyLarge!.copyWith(
                    color: Colors.green[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'de ${formatoMoneda.format(meta.montoObjetivo)}',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                meta.progreso >= 100
                    ? '🎉 ¡Meta cumplida!'
                    : 'Progreso: ${meta.progreso.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: meta.progreso >= 100 ? Colors.green : Colors.blueGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ButtonBar(
              alignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: 'Depositar',
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => onTransaccion('deposito'),
                ),
                IconButton(
                  tooltip: 'Retirar',
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => onTransaccion('retiro'),
                ),
                IconButton(
                  tooltip: 'Ver detalles',
                  icon: const Icon(Icons.info_outline, color: Colors.blue),
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
