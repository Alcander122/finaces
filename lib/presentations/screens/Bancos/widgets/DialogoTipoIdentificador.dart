import 'package:flutter/material.dart';
import 'package:finances/core/data/models/bank_model.dart';

/// Diálogo que permite al usuario seleccionar el tipo de identificador bancario
///
/// IMPORTANTE: Este diálogo recibe un BancoModelo completo con userId válido
/// porque ya pasó por el proceso de selección de banco con userId real
class DialogoTipoIdentificador extends StatelessWidget {
  final BancoModelo banco;
  final Function(String) onTipoSeleccionado;

  const DialogoTipoIdentificador({
    super.key,
    required this.banco,
    required this.onTipoSeleccionado,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Seleccionar tipo de identificador para ${banco.nombre}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.numbers),
            title: const Text('Número de cuenta'),
            subtitle: const Text('10-20 dígitos numéricos (ej: 1234567890)'),
            onTap: () => onTipoSeleccionado('cuenta'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('Llave bancaria'),
            subtitle: const Text(
                '3 partes alfanuméricas (mínimo 5 caracteres cada una)'),
            onTap: () => onTipoSeleccionado('llave'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
