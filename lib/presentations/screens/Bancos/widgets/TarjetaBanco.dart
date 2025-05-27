import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/bank_model.dart';
import 'package:finances/core/data/providers/bank_provider.dart';
import 'package:share_plus/share_plus.dart';

// Función auxiliar para enmascarar el número de cuenta
String maskAccountNumber(String accountNumber) {
  if (accountNumber.length <= 4) return accountNumber;
  return '*' * (accountNumber.length - 4) +
      accountNumber.substring(accountNumber.length - 4);
}

// Widget que muestra un banco como una tarjeta con opciones de acción
class TarjetaBanco extends ConsumerWidget {
  final BancoModelo banco;
  const TarjetaBanco({super.key, required this.banco});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mostrar nombre del banco y número de cuenta enmascarado
            Text(
              '${banco.nombre} ${maskAccountNumber(banco.numeroCuenta)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botón para eliminar el banco (solo si tiene ID válido)
                if (banco.id.isNotEmpty && banco.userId.isNotEmpty)
                  ElevatedButton(
                    onPressed: () => _mostrarDialogoEliminarBanco(context, ref),
                    child: const Text('Eliminar'),
                  ),
                if (banco.id.isNotEmpty && banco.userId.isNotEmpty)
                  const SizedBox(width: 8),
                // Botón para compartir la información del banco
                ElevatedButton.icon(
                  onPressed: () => _compartirCuenta(context, banco),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Compartir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Función para compartir la información del banco
  void _compartirCuenta(BuildContext context, BancoModelo banco) {
    final message =
        'Banco: ${banco.nombre}\nNúmero de cuenta: ${banco.numeroCuenta}';
    Share.share(message);
  }

  // Diálogo para confirmar la eliminación del banco
  void _mostrarDialogoEliminarBanco(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de querer eliminar este banco?'),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (banco.id.isNotEmpty && banco.userId.isNotEmpty) {
                  // Acceder al notifier del provider familiar con el userId
                  await ref
                      .read(bancoNotifierProvider(banco.userId).notifier)
                      .eliminarBanco(banco.id, banco.userId);
                  Navigator.of(context).pop();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al eliminar: $e')),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
