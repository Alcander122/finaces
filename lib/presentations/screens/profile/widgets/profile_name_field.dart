// profile_name_field.dart
import 'package:flutter/material.dart';

/// Campo de texto para editar el nombre en estilo premium dark mode
class ProfileNameField extends StatelessWidget {
  final TextEditingController controller;
  const ProfileNameField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Nombre Completo',
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        hintText: 'Tu nombre',
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF26A69A), width: 1.5), // Esmeralda al enfocar
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5), // Coral para errores
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2.0),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor, ingresa un nombre';
        }
        final trimmed = value.trim();
        if (trimmed.length < 3) return 'El nombre debe tener al menos 3 caracteres';
        if (trimmed.length > 30) return 'El nombre no debe exceder los 30 caracteres';
        final validNameRegExp = RegExp(r'^[a-zA-Z0-9\síóáéúÍÓÁÉÚñÑüÜ]+$'); // Permite tildes y ñ
        if (!validNameRegExp.hasMatch(trimmed)) {
          return 'Solo se permiten letras, números y espacios';
        }
        return null;
      },
    );
  }
}
