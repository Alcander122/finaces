import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Para usar ref
import 'package:finances/core/data/models/bank_model.dart';
import 'package:finances/core/data/providers/bank_provider.dart';
import 'package:finances/presentations/theme/themes.dart';

class TarjetaBanco extends ConsumerWidget { // ✅ Usa ConsumerWidget
  final BancoModelo banco;

  const TarjetaBanco({super.key, required this.banco});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _crearEncabezadoBanco(context),
            const Divider(),
            _crearNumeroCuenta(context),
            const SizedBox(height: 16),
            _crearBotonesAccion(context),
            const SizedBox(height: 16),
            _crearAccionesBanco(context, ref), // ✅ Pasa ref
          ],
        ),
      ),
    );
  }

  // Encabezado con nombre del banco y calificación
  Row _crearEncabezadoBanco(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.account_balance), // ✅ Icono válido
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                banco.nombre,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, size: 14),
                  Text('4.5', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Campo de número de cuenta (enmascarado)
  Widget _crearNumeroCuenta(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Número de Cuenta',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            banco.numeroCuentaEnmascarado,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // Botones de acción (Copiar y Compartir)
  Row _crearBotonesAccion(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () => _copiarNumeroCuenta(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor, // ✅ primaryColor obtenido del contexto
          ),
          child: const Text('Copiar'),
        ),
        ElevatedButton(
          onPressed: () => _mostrarDialogoCompartir(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
          ),
          child: const Text('Compartir'),
        ),
      ],
    );
  }

  // Acciones adicionales (Editar y Eliminar)
  Row _crearAccionesBanco(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editarBanco(context),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _eliminarBanco(context, ref), // ✅ Pasa ref
        ),
      ],
    );
  }

  // Diálogo para compartir información del banco
  void _mostrarDialogoCompartir(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(banco.nombre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Número de cuenta: ${banco.numeroCuenta}'), // Mostrar número completo
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.add_call), // ✅ Icono de WhatsApp
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.email),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.message),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  // Copiar número de cuenta al portapapeles
  void _copiarNumeroCuenta(BuildContext context) {
    // Implementar lógica con paquete clipboard o flutter_clipboard_manager
  }

  // Editar información del banco
  void _editarBanco(BuildContext context) {
    // Implementar lógica de edición
  }

  // Eliminar un banco
  void _eliminarBanco(BuildContext context, WidgetRef ref) {
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
              ref.read(proveedorBancos.notifier).eliminarBanco(banco.id);
              Navigator.of(context).pop();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}