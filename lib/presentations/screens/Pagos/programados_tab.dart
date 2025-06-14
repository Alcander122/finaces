// Tab de pagos programados (refactorizado)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/payment_provider.dart';
import 'package:finances/presentations/screens/Pagos/widgets/pago_item_widget.dart';
import 'package:finances/presentations/screens/Pagos/widgets/empty_state_widget.dart';
import 'package:finances/presentations/screens/Pagos/widgets/confirm_delete_dialog.dart';

class ProgramadosTab extends ConsumerWidget {
  final String userId;

  const ProgramadosTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState.user == null) {
      return const Center(child: Text("Usuario no autenticado"));
    }

    final pagosAsync = ref.watch(paymentProvider(userId));

    return pagosAsync.when(
      data: (pagos) {
        final programados = pagos.where((p) => p.estaProgramado).toList();

        if (programados.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.calendar_today,
            title: "No hay pagos programados",
            message: "Presiona el botón + para agregar uno nuevo",
          );
        }

        return ListView.builder(
          itemCount: programados.length,
          itemBuilder: (context, index) {
            final pago = programados[index];
            return PagoItemWidget(
              pago: pago,
              icon: Icons.calendar_today,
              color: Colors.green,
              textoFecha: 'Próximo',
              onEditar: () => Navigator.pushNamed(
                context, 
                '/editar-pago',
                arguments: pago,
              ),
              onEliminar: () => _eliminarPago(context, ref, pago.id),
            );
          },
        );
      },
      error: (err, stack) => Center(child: Text("Error: $err")),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _eliminarPago(BuildContext context, WidgetRef ref, String pagoId) async {
    final confirm = await showConfirmDeleteDialog(context);
    if (confirm == true) {
      try {
        await ref.read(paymentProvider(userId).notifier).eliminarPago(pagoId);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error eliminando pago: $e")),
        );
      }
    }
  }
}