import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/bank_model.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:share_plus/share_plus.dart';
import 'qr_screen.dart';

String maskAccountNumber(String accountNumber) {
  if (accountNumber.length <= 4) return accountNumber;
  return '*' * (accountNumber.length - 4) +
      accountNumber.substring(accountNumber.length - 4);
}

class TarjetaBanco extends ConsumerWidget {
  final BancoModelo banco;
  final VoidCallback onEliminar;

  const TarjetaBanco({
    super.key,
    required this.banco,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Card(
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Themes.degradientLight, Themes.degradientDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Nombre del banco
                  Text(
                    banco.nombre,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Themes.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Número de cuenta
                  Text(
                    maskAccountNumber(banco.numeroCuenta),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botones principales
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Botón Ver QR
                      ElevatedButton.icon(
                        onPressed: () => _mostrarQR(context),
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Ver QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Themes.degradientDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      // Botón Compartir
                      ElevatedButton.icon(
                        onPressed: () => _compartirCuenta(),
                        icon: const Icon(Icons.share),
                        label: const Text('Compartir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Themes.degradientDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Botón flotante redondo para eliminar.
        Positioned(
          bottom: 6,
          left: 6,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _confirmarEliminacion(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.15),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.delete,
                  size: 20,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _compartirCuenta() {
    final mensaje =
        'Banco: ${banco.nombre}\nNúmero de cuenta: ${banco.numeroCuenta}';
    Share.share(mensaje);
  }

  void _mostrarQR(BuildContext context) {
    final dataQR =
        'Banco: ${banco.nombre}\nNúmero de cuenta: ${banco.numeroCuenta}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScreen(data: dataQR),
      ),
    );
  }

  void _confirmarEliminacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar cuenta bancaria?'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar esta cuenta bancaria? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancelar
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              onEliminar(); // Ejecuta eliminación
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
