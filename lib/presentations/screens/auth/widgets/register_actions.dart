// register_actions.dart
// Componente que maneja los botones de acción en la pantalla de registro
// Propósito: Centralizar la UI y lógica de los botones (registro, Google, login)
// Autor: [Tu nombre]
// Última modificación: [Fecha]

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Componente que encapsula todos los botones de acción en la pantalla de registro
///
/// Mantiene la pantalla principal limpia al separar la lógica de los botones
class RegisterActions extends StatelessWidget {
  const RegisterActions({
    required this.isLoading,
    required this.onRegister,
    required this.onGoogleSignIn,
    required this.onLoginTap,
    super.key,
  });

  /// Indica si el proceso de registro está en carga
  final bool isLoading;

  /// Callback para registrar al usuario
  final VoidCallback onRegister;

  /// Callback para iniciar sesión con Google
  final VoidCallback onGoogleSignIn;

  /// Callback para navegar a la pantalla de login
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botón de registro principal
        _buildRegisterButton(),
        const SizedBox(height: 30.0),

        // Botones de login con Google
        _buildGoogleLogin(),
        const SizedBox(height: 30.0),

        // Enlace para usuarios existentes
        _buildLoginLink(),
      ],
    );
  }

  /// Botón principal para registrar al usuario
  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Registrar'),
      ),
    );
  }

  /// Botón para iniciar sesión con Google
  Widget _buildGoogleLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: onGoogleSignIn,
          child: const FaIcon(FontAwesomeIcons.google, color: Color(0xFFEA4335), size: 28),
        ),
      ],
    );
  }

  /// Enlace para navegar a la pantalla de login
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿Ya tienes una cuenta? ',
            style: TextStyle(color: Colors.black45)),
        GestureDetector(
          onTap: onLoginTap,
          child: Text(
            'Inicia sesión',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
