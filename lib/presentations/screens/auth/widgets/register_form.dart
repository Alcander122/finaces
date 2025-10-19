// register_form.dart
// Componente que contiene todos los campos de texto del formulario de registro
// Propósito: Organizar la UI de los campos de entrada para mantener RegisterScreen limpio
// Autor: [Tu nombre]
// Última modificación: [Fecha]

import 'package:flutter/material.dart';
import 'package:finances/core/errors/error_strings.dart';

/// Componente que encapsula todos los campos de texto del formulario de registro
///
/// Separa la lógica de los campos de la pantalla principal para mejorar mantenibilidad
class RegisterForm extends StatelessWidget {
  const RegisterForm({
    required this.nameController,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isPasswordVisible,
    required this.isConfirmPasswordVisible,
    required this.onPasswordVisibilityToggle,
    required this.onConfirmPasswordVisibilityToggle,
    super.key,
  });

  /// Controlador para el campo de nombre completo
  final TextEditingController nameController;

  /// Controlador para el campo de nombre de usuario
  final TextEditingController usernameController;

  /// Controlador para el campo de correo electrónico
  final TextEditingController emailController;

  /// Controlador para el campo de contraseña
  final TextEditingController passwordController;

  /// Controlador para el campo de confirmación de contraseña
  final TextEditingController confirmPasswordController;

  /// Estado de visibilidad de la contraseña
  final bool isPasswordVisible;

  /// Estado de visibilidad de la confirmación de contraseña
  final bool isConfirmPasswordVisible;

  /// Callback para alternar visibilidad de la contraseña
  final VoidCallback onPasswordVisibilityToggle;

  /// Callback para alternar visibilidad de la confirmación de contraseña
  final VoidCallback onConfirmPasswordVisibilityToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildNameField(),
        const SizedBox(height: 25.0),
        _buildUsernameField(),
        const SizedBox(height: 25.0),
        _buildEmailField(),
        const SizedBox(height: 25.0),
        _buildPasswordField(),
        const SizedBox(height: 25.0),
        _buildConfirmPasswordField(),
        const SizedBox(height: 25.0),
      ],
    );
  }

  /// Campo de texto para el nombre completo del usuario
  Widget _buildNameField() {
    return TextFormField(
      controller: nameController,
      validator: (value) =>
          value?.isEmpty ?? true ? ErrorStrings.requiredField : null,
      decoration: _inputDecoration('Nombre Completo'),
    );
  }

  /// Campo de texto para el nombre de usuario
  Widget _buildUsernameField() {
    return TextFormField(
      controller: usernameController,
      validator: (value) =>
          value?.isEmpty ?? true ? ErrorStrings.requiredField : null,
      decoration: _inputDecoration('Nombre Usuario'),
    );
  }

  /// Campo de texto para el correo electrónico con validación
  Widget _buildEmailField() {
    return TextFormField(
      controller: emailController,
      validator: (value) {
        if (value == null || value.isEmpty) return ErrorStrings.requiredField;
        if (!_validateEmail(value)) return ErrorStrings.invalidEmail;
        return null;
      },
      decoration: _inputDecoration('Correo'),
    );
  }

  /// Campo de texto para la contraseña con visibilidad toggle
  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: !isPasswordVisible,
      validator: (value) =>
          value?.isEmpty ?? true ? ErrorStrings.requiredField : null,
      decoration: _inputDecoration('Contraseña').copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: onPasswordVisibilityToggle,
        ),
      ),
    );
  }

  /// Campo de texto para confirmar la contraseña con validación cruzada
  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: confirmPasswordController,
      obscureText: !isConfirmPasswordVisible,
      validator: (value) {
        if (value == null || value.isEmpty) return ErrorStrings.requiredField;
        if (value != passwordController.text)
          return ErrorStrings.passwordMismatch;
        return null;
      },
      decoration: _inputDecoration('Confirmar Contraseña').copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: onConfirmPasswordVisibilityToggle,
        ),
      ),
    );
  }

  /// Estilo de decoración común para todos los campos de texto
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      hintText: 'Ingresa $label',
      hintStyle: const TextStyle(color: Colors.black26),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black12),
      ),
    );
  }

  /// Valida el formato del correo electrónico
  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }
}
