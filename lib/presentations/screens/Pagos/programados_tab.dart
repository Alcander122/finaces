import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/presentations/screens/Pagos/providers/payment_providers.dart';
import 'package:finances/presentations/screens/Pagos/widgets/pago_item_widget.dart';
import 'package:finances/presentations/screens/Pagos/widgets/empty_state_widget.dart';
import 'package:finances/presentations/screens/Pagos/widgets/confirm_delete_dialog.dart';
import 'package:finances/presentations/screens/Pagos/models/payment.dart';
import 'package:finances/presentations/screens/Pagos/models/payment_enums.dart';

import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/core/errors/handlers/db_error_handler.dart';

class ProgramadosTab extends ConsumerWidget {
  final String userId;

  const ProgramadosTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState.user == null) {
      return const Center(child: Text("Usuario no autenticado"));
    }

    final pagosAsync = ref.watch(paymentsStreamProvider(userId));

    return pagosAsync.when(
      data: (pagos) {
        final programados = pagos
            .where((p) => p.recurrence.unit != FrequencyUnit.none)
            .toList();

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
              onCompletar: () => _completarPago(context, ref, pago),
            );
          },
        );
      },
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                DbErrorHandler.handle(err),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                onPressed: () => ref.invalidate(paymentsStreamProvider(userId)),
              ),
            ],
          ),
        ),
      ),
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
            context: context, message: DbErrorHandler.handle(e));
      }
    }
  }

  Future<void> _completarPago(
      BuildContext context, WidgetRef ref, Payment pago) async {
    try {
      await ref
          .read(paymentControllerProvider.notifier)
          .payPayment(pago);
      if (!context.mounted) return;
      UIHelpers.showSuccessSnackBar(
        context: context,
        message: 'Pago registrado y programado para el siguiente ciclo',
      );
    } catch (e) {
      if (!context.mounted) return;
      UIHelpers.showErrorSnackBar(
        context: context,
        message: DbErrorHandler.handle(e),
      );
    }
  }
}
