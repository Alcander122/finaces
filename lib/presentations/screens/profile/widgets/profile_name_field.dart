// profile_name_field.dart
import 'package:flutter/material.dart';
import 'package:finances/presentations/theme/themes.dart';

/// Campo de texto para editar el nombre
class ProfileNameField extends StatelessWidget {
  final TextEditingController controller;
  const ProfileNameField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Nombre',
        prefixIcon: const Icon(Icons.person, color: Themes.iconColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor, ingresa un nombre';
        }
        final trimmed = value.trim();
        if (trimmed.length < 3) return 'El nombre debe tener al menos 3 caracteres';
        if (trimmed.length > 30) return 'El nombre no debe exceder los 30 caracteres';
        final validNameRegExp = RegExp(r'^[a-zA-Z0-9\s]+$');
        if (!validNameRegExp.hasMatch(trimmed)) {
          return 'Solo se permiten letras, números y espacios';
        }
        return null;
      },
    );
  }
}
