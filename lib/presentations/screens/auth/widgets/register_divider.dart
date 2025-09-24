// register_divider.dart
// Componente que muestra el separador entre secciones en la pantalla de registro
// Propósito: Centralizar el diseño del separador para mantener consistencia
// Autor: [Tu nombre]
// Última modificación: [Fecha]

import 'package:flutter/material.dart';

/// Componente que muestra una línea divisoria con texto en el centro
///
/// Se usa para separar secciones en la UI (ej: formulario y login alternativo)
class RegisterDivider extends StatelessWidget {
  const RegisterDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Divider(
                color: Colors.grey.withAlpha(128),
                thickness: 0.7,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('Iniciar sesión',
                  style: TextStyle(color: Colors.black45)),
            ),
            Expanded(
              child: Divider(
                color: Colors.grey.withAlpha(128),
                thickness: 0.7,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30.0),
      ],
    );
  }
}
