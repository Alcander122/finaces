import 'package:flutter/material.dart';
import 'package:finances/presentations/theme/themes.dart';

class FormStyles {
  // ============================================================================
  // 🎨 DECORACIONES DE ENTRADA DE TEXTO
  // ============================================================================

  /// Crea una decoración estándar para campos de texto
  ///
  /// Parámetros:
  /// - labelText: Etiqueta del campo (ej: "Fecha Ingreso")
  /// - suffixIcon: Icono a la derecha (ej: Icons.calendar_today)
  /// - hintText: Texto de ayuda dentro del campo
  /// - prefixIcon: Icono a la izquierda
  ///
  /// Ejemplo:
  /// ```dart
  /// TextFormField(
  ///   decoration: FormStyles.buildInputDecoration(
  ///     labelText: 'Fecha Ingreso',
  ///     suffixIcon: Icons.calendar_today,
  ///   ),
  /// )
  /// ```
  static InputDecoration buildInputDecoration({
    required String labelText,
    IconData? suffixIcon,
    String? hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      // Etiqueta del campo
      labelText: labelText,
      labelStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),

      // Texto de ayuda
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 13,
      ),

      // Borde normal (no enfocado)
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      // Borde cuando está habilitado pero no enfocado
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),

      // Borde cuando está enfocado
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Themes.primary, width: 2),
      ),

      // Borde cuando hay error
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),

      // Borde cuando hay error y está enfocado
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),

      // Iconos
      suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
      prefixIcon: prefixIcon,

      // Espaciado interno
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      // Estilo del texto de error
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 12,
      ),
    );
  }

  // ============================================================================
  // 🔘 ESTILOS DE BOTONES
  // ============================================================================

  /// Estilo para botones primarios (Guardar, Enviar, etc)
  ///
  /// Ejemplo:
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: _saveForm,
  ///   style: FormStyles.buildPrimaryButtonStyle(),
  ///   child: const Text('Guardar'),
  /// )
  /// ```
  static ButtonStyle buildPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      // Color de fondo
      backgroundColor: Themes.primary,

      // Espaciado interno
      padding: const EdgeInsets.symmetric(vertical: 16),

      // Forma del botón
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      // Sombra
      elevation: 2,
    );
  }

  /// Estilo para botones secundarios (Cancelar, Volver, etc)
  ///
  /// Ejemplo:
  /// ```dart
  /// OutlinedButton(
  ///   onPressed: _cancel,
  ///   style: FormStyles.buildSecondaryButtonStyle(),
  ///   child: const Text('Cancelar'),
  /// )
  /// ```
  static ButtonStyle buildSecondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      // Espaciado interno
      padding: const EdgeInsets.symmetric(vertical: 16),

      // Forma del botón
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      // Borde
      side: const BorderSide(color: Colors.grey, width: 1),
    );
  }

  // ============================================================================
  // 📏 ESPACIADOS ESTÁNDAR
  // ============================================================================

  /// Espaciado entre campos del formulario (16.0)
  /// Uso: const SizedBox(height: FormStyles.fieldSpacing)
  static const double fieldSpacing = 16.0;

  /// Espaciado entre secciones del formulario (24.0)
  /// Uso: const SizedBox(height: FormStyles.sectionSpacing)
  static const double sectionSpacing = 24.0;

  // ============================================================================
  // 📦 PADDING ESTÁNDAR PARA CONTENEDORES
  // ============================================================================

  /// Padding estándar para contenedores de formularios
  /// Uso: Container(padding: FormStyles.containerPadding, ...)
  static const EdgeInsets containerPadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 16);

  // ============================================================================
  // 🔲 BORDER RADIUS ESTÁNDAR
  // ============================================================================

  /// Border radius estándar para todos los elementos (12.0)
  /// Uso: BorderRadius.circular(FormStyles.borderRadius)
  static const double borderRadius = 12.0;

  // ============================================================================
  // 📝 ESTILOS DE TEXTO
  // ============================================================================

  /// Estilo para etiquetas de campos
  static const TextStyle labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.grey,
  );

  /// Estilo para mensajes de error
  static const TextStyle errorStyle = TextStyle(
    fontSize: 12,
    color: Colors.red,
  );

  /// Estilo para títulos de secciones
  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
}
