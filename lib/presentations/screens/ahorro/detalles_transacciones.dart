import 'package:finances/core/data/models/objetivo_ahorro.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/data/utils/ui_helpers.dart';

class DetallesTransacciones extends StatelessWidget {
  final ObjetivoAhorro meta;

  const DetallesTransacciones({required this.meta, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBgColor,
      appBar: AppBarFinances(
        title: 'Detalles de ${meta.nombre}',
        showProfileIcon: false,
      ),
      body: meta.transacciones.isEmpty
          ? const Center(
              child: Text(
                'No hay transacciones registradas',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: meta.transacciones.length,
              itemBuilder: (context, index) {
                final transaccion = meta.transacciones[index];
                final String tipoFormatted = transaccion.tipo[0].toUpperCase() +
                    transaccion.tipo.substring(1);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      transaccion.tipo == 'deposito' ? Icons.add : Icons.remove,
                      color: transaccion.tipo == 'deposito'
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: Text(
                      '$tipoFormatted - ${UIHelpers.formatCurrency(transaccion.monto)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${DateFormat('yyyy-MM-dd HH:mm').format(transaccion.fecha)}\n${transaccion.descripcion ?? 'Sin descripción'}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
