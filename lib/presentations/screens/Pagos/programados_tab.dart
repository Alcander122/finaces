import 'package:finances/core/data/models/pago_model.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/payment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Para formatear fechas

class ProgramadosTab extends ConsumerWidget {
    final String userId;
  const ProgramadosTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.user == null) {
      return const Center(child: Text("Usuario no autenticado"));
    }

    final userId = authState.user!.uid;
    final pagosAsync = ref.watch(paymentProvider(userId));

    return pagosAsync.when(
      data: (pagos) {
        // Filtrar pagos programados
        final programados = pagos.where((p) => p.estaProgramado).toList();

        // Estado vacío mejorado
        if (programados.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "No hay pagos programados",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  "Presiona el botón + para agregar uno nuevo",
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Lista con tarjetas para mejor presentación
        return ListView.builder(
          itemCount: programados.length,
          itemBuilder: (context, index) {
            final pago = programados[index];
            return _buildPagoItem(context, ref, pago, userId);
          },
        );
      },
      error: (err, stack) => Center(child: Text("Error: $err")),
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Cargando pagos programados..."),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar cada ítem de pago
  Widget _buildPagoItem(BuildContext context, WidgetRef ref, Pago pago, String userId) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.calendar_today, color: Colors.green),
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
              'Monto: \$${pago.monto.toStringAsFixed(2)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 2),
            Text(
              'Próximo: ${DateFormat('dd/MM/yyyy').format(pago.fechaVencimiento)}',
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
              onPressed: () => Navigator.pushNamed(
                context, 
                '/editar-pago',
                arguments: pago,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmarEliminacion(context, ref, pago.id, userId),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo de confirmación para eliminar
  Future<void> _confirmarEliminacion(
      BuildContext context, WidgetRef ref, String pagoId, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: const Text("¿Estás seguro de eliminar este pago?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(paymentProvider(userId).notifier).eliminarPago(pagoId);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error eliminando pago: $e")),
        );
      }
    }
  }
}