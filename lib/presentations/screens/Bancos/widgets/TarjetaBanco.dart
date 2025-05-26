import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/bank_model.dart';
import 'package:finances/core/data/providers/bank_provider.dart';
import 'package:share_plus/share_plus.dart';

// Utility Function
String maskAccountNumber(String accountNumber) {
  if (accountNumber.length <= 4) return accountNumber;
  return '*' * (accountNumber.length - 4) + accountNumber.substring(accountNumber.length - 4);
}

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
            // Display masked account number
            Text(
              '${banco.nombre} ${maskAccountNumber(banco.numeroCuenta)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Delete Button
                ElevatedButton(
                  onPressed: () => _mostrarDialogoEliminarBanco(context, ref),
                  child: const Text('Eliminar'),
                ),
                const SizedBox(width: 8),
                // Share Button
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

  void _compartirCuenta(BuildContext context, BancoModelo banco) {
    final message = 'Banco: ${banco.nombre}\nNúmero de cuenta: ${banco.numeroCuenta}';
    Share.share(message);
  }

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
            onPressed: () {
              ref.read(bancoNotifierProvider.notifier).eliminarBanco(banco.id, banco.userId);
              Navigator.of(context).pop();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}