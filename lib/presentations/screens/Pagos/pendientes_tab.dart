// Tab de pagos pendientes (refactorizado)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/presentations/screens/Pagos/providers/payment_providers.dart';
import 'package:finances/presentations/screens/Pagos/widgets/pago_item_widget.dart';
import 'package:finances/presentations/screens/Pagos/widgets/empty_state_widget.dart';
import 'package:finances/presentations/screens/Pagos/widgets/confirm_delete_dialog.dart';
import 'package:finances/presentations/screens/Pagos/models/payment_enums.dart';

import '../../../utils/ui_helpers.dart';

class PendientesTab extends ConsumerWidget {
  final String userId;

  const PendientesTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState.user == null) {
      return const Center(child: Text("Usuario no autenticado"));
    }

    final pagosAsync = ref.watch(paymentsStreamProvider(userId));

    return pagosAsync.when(
      data: (pagos) {
        final pendientes = pagos
            .where((p) =>
                p.recurrence.unit == FrequencyUnit.none && p.id.isNotEmpty)
            .toList();

        print('DEBUG: Pagos pendientes filtrados: ${pendientes.length}');

        if (pendientes.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.payment,
            title: "No hay pagos pendientes",
            message: "Presiona el botón + para agregar uno nuevo",
          );
        }

        return ListView.builder(
          itemCount: pendientes.length,
          itemBuilder: (context, index) {
            final pago = pendientes[index];
            return PagoItemWidget(
              pago: pago,
              icon: Icons.access_time,
              color: Colors.orange,
              textoFecha: 'Vence',
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

  Future<void> _eliminarPago(
      BuildContext context, WidgetRef ref, String pagoId) async {
    final confirm = await showConfirmDeleteDialog(context);
    if (confirm == true) {
      try {
        await ref
            .read(paymentControllerProvider.notifier)
            .deletePayment(userId, pagoId);
      } catch (e) {
        if (!context.mounted) return;
        UIHelpers.showErrorSnackBar(
          context: context,
          message: "Error eliminando pago: $e",
        );
      }
    }
  }
}
