import 'package:flutter/material.dart';
import 'package:finances/core/data/models/bank_model.dart';

class DialogoSeleccionarBanco extends StatelessWidget {
  final Function(BancoModelo) onSeleccionar;

  const DialogoSeleccionarBanco({
    super.key,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    // Lista de bancos disponibles (deberías obtenerla de tu fuente de datos)
    final bancosDisponibles = [
      BancoModelo(id: '1', nombre: 'Banco Popular', numeroCuenta: '', userId: ''),
      BancoModelo(id: '2', nombre: 'Banco de Chile', numeroCuenta: '', userId: ''),
      BancoModelo(id: '3', nombre: 'Scotiabank', numeroCuenta: '', userId: ''),
      BancoModelo(id: '4', nombre: 'Itaú', numeroCuenta: '', userId: ''),
      BancoModelo(id: '5', nombre: 'Banco Santander', numeroCuenta: '', userId: ''),
    ];

    return AlertDialog(
      title: const Text('Selecciona tu banco'),
      content: ConstrainedBox(
        // Limita el alto máximo al 70% del alto de la pantalla
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          // Para permitir scroll si hay muchos elementos
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ocupa solo el espacio necesario
            children: [
              // Mapeamos cada banco a un ListTile
              ...bancosDisponibles.map(
                (banco) => ListTile(
                  title: Text(banco.nombre),
                  onTap: () {
                    Navigator.pop(context); // Cierra el diálogo
                    onSeleccionar(banco); // Notifica la selección
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                  minVerticalPadding: 12.0, // Espaciado vertical mínimo
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
      insetPadding: const EdgeInsets.all(20.0), // Margen en todos los lados
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0), // Bordes redondeados
      ),
    );
  }
}
