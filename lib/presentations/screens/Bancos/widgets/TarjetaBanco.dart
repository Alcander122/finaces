import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/bank_model.dart';
import 'package:finances/core/data/providers/bank_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'qr_screen.dart'; // Importa la pantalla para mostrar el código QR

// Función para enmascarar el número de cuenta, dejando visibles solo los últimos 4 dígitos
String maskAccountNumber(String accountNumber) {
  if (accountNumber.length <= 4) return accountNumber;
  return '*' * (accountNumber.length - 4) +
      accountNumber.substring(accountNumber.length - 4);
}

// Widget que representa una tarjeta con la información del banco
class TarjetaBanco extends ConsumerWidget {
  final BancoModelo banco; // Modelo con la información del banco

  const TarjetaBanco({super.key, required this.banco});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context); // Obtiene el tema actual de la app

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del banco en texto grande y en negrita
            Text(
              banco.nombre,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Muestra el número de cuenta enmascarado
            Text(
              maskAccountNumber(banco.numeroCuenta),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.primary),
            ),

            const SizedBox(height: 12),

            // Botones para ver el QR y compartir la cuenta
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                // Botón para ver el código QR
                ElevatedButton.icon(
                  onPressed: () => _mostrarQR(context),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Ver QR'),
                ),

                // Botón para compartir los datos de la cuenta
                ElevatedButton.icon(
                  onPressed: () => _compartirCuenta(context, banco),
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Función para compartir los datos del banco usando share_plus
  void _compartirCuenta(BuildContext context, BancoModelo banco) {
    final mensaje =
        'Banco: ${banco.nombre}\nNúmero de cuenta: ${banco.numeroCuenta}';
    Share.share(mensaje); // Llama al plugin para compartir texto
  }

  // Navega a la pantalla del QR pasando los datos del banco
  void _mostrarQR(BuildContext context) {
    final dataQR =
        'Banco: ${banco.nombre}\nNúmero de cuenta: ${banco.numeroCuenta}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScreen(data: dataQR), // Construye la pantalla QR
      ),
    );
  }
}
