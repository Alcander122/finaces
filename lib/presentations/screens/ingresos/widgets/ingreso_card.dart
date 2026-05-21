import 'package:finances/core/data/services/ingresos_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/presentations/screens/ingresos/widgets/ingreso_form_bottom_sheet.dart';

class IngresoCard extends ConsumerWidget {
  final Ingreso ingreso;

  const IngresoCard({super.key, required this.ingreso});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Formateador de moneda colombiana
    final currencyFormat =
        NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    void _mostrarFormulario(BuildContext context) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => IngresoFormBottomSheet(ingresoToEdit: ingreso),
      );
    }

    return Dismissible(
      // ValueKey y un fallback garantizan que no existan Key duplicadas
      key: ValueKey(ingreso.id ?? ingreso.hashCode.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) async {
        // Acción optimista (Optimistic UI)
        final controller = ref.read(ingresosControllerProvider.notifier);
        await controller.eliminarIngreso(ingreso);

        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Ingreso eliminado'),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'DESHACER',
                textColor: Colors.white,
                onPressed: () => controller.deshacerEliminacion(),
              ),
            ),
          );
        }
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: Colors.green.shade50,
            child: Icon(Icons.arrow_upward, color: Colors.green.shade700),
          ),
          title: Text(
            ingreso.concepto,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle:
              // Se formatea la fecha directamente para evitar errores si no existe el getter
              Text(
                  '${ingreso.categoria} • ${DateFormat('dd/MM/yyyy').format(ingreso.fecha ?? DateTime.now())}'),
          trailing: Text(
            currencyFormat.format(ingreso.valor),
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
          ),
          onTap: () => _mostrarFormulario(context),
        ),
      ),
    );
  }
}
