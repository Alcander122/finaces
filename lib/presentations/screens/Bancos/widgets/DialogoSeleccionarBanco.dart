// Diálogo para seleccionar un banco de una lista
import 'package:flutter/material.dart';
import 'package:finances/core/data/models/bank_model.dart';

class DialogoSeleccionarBanco extends StatelessWidget {
  final Function(BancoModelo) onSeleccionar;

  const DialogoSeleccionarBanco({super.key, required this.onSeleccionar});

  @override
  Widget build(BuildContext context) {
    final bancosDisponibles = [
      BancoModelo(
        id: '1',
        nombre: 'Banco Popular',
        numeroCuenta: '', // Campo requerido
      ),
      BancoModelo(
        id: '2',
        nombre: 'Banco de Chile',
        numeroCuenta: '', // Campo requerido
      ),
      BancoModelo(
        id: '3',
        nombre: 'Scotiabank',
        numeroCuenta: '',
      ),
      BancoModelo(
        id: '4',
        nombre: 'Itaú',
        numeroCuenta: '',
      ),
      BancoModelo(
        id: '5',
        nombre: 'Banco Santander',
        numeroCuenta: '',
      ),
    ];

    return AlertDialog(
      title: const Text('Selecciona tu banco'),
      content: SizedBox(
        height: 300,
        child: ListView.builder(
          itemCount: bancosDisponibles.length,
          itemBuilder: (context, indice) {
            final banco = bancosDisponibles[indice];
            return ListTile(
              title: Text(banco.nombre),
              onTap: () {
                Navigator.pop(context); // Cerrar diálogo
                onSeleccionar(banco); // Ejecutar acción
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}