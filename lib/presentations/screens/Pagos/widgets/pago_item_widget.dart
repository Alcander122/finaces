// pago_item_widget.dart
import '../models/payment.dart';
import '../models/payment_enums.dart';
import '../utils/next_due_date_calculator.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finances/presentations/theme/themes.dart';

class PagoItemWidget extends StatelessWidget {
  final Payment pago;
  final IconData icon;
  final Color color;
  final String textoFecha;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback onCompletar;

  const PagoItemWidget({
    super.key,
    required this.pago,
    required this.icon,
    required this.color,
    required this.textoFecha,
    required this.onEditar,
    required this.onEliminar,
    required this.onCompletar,
  });

  String _formatNextDueDate(Payment pago) {
    if (textoFecha == 'Próximo' && pago.recurrence.unit != FrequencyUnit.none) {
      final nextFuture = NextDueDateCalculator.calculateNextFutureDate(pago);
      return DateFormat('dd/MM/yyyy').format(nextFuture);
    }
    final date = pago.nextDueDate;
    return date != null ? DateFormat('dd/MM/yyyy').format(date) : 'No definido';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contenedor del Icono
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                
                // Detalles del Pago (Título, Monto, Fecha)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pago.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Themes.primary,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Monto: ${UIHelpers.formatCurrency(pago.totalAmount)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$textoFecha: ${_formatNextDueDate(pago)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade200, thickness: 1),
            const SizedBox(height: 12),
            
            // Acciones en un Wrap responsivo alineado a la derecha
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ActionButton(
                  icon: Icons.check_circle_outline,
                  label: 'Pagado',
                  color: Colors.green,
                  onPressed: onCompletar,
                ),
                _ActionButton(
                  icon: Icons.edit,
                  label: 'Editar',
                  color: Colors.blue,
                  onPressed: onEditar,
                ),
                _ActionButton(
                  icon: Icons.delete,
                  label: 'Eliminar',
                  color: Colors.red,
                  onPressed: onEliminar,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: onPressed,
    );
  }
}
