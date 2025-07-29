// Widget reusable para ítems de pago (pendientes y programados)
import 'package:finances/core/data/models/pago_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PagoItemWidget extends StatelessWidget {
  final Pago pago;
  final IconData icon;
  final Color color;
  final String textoFecha;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const PagoItemWidget({
    super.key,
    required this.pago,
    required this.icon,
    required this.color,
    required this.textoFecha,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          pago.descripcion,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Monto: \$${NumberFormat("#,###", "es_CO").format(pago.monto.round())}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 2),
            Text(
              '$textoFecha: ${DateFormat('dd/MM/yyyy').format(pago.fechaVencimiento)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEditar,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onEliminar,
            ),
          ],
        ),
      ),
    );
  }
}
