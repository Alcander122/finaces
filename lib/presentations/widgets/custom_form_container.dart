// 📌 custom_form_container.dart
// ============================================================================
// ARCHIVO: presentations/widgets/custom_form_container.dart
// PROPÓSITO: Contenedor mejorado para formularios
// DESCRIPCIÓN: Versión mejorada del contenedor original con estilos centralizados
// ============================================================================

import 'package:flutter/material.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/widgets/form_styles.dart';

class CustomFormContainer extends StatelessWidget {
  // ============================================================================
  // 📋 PROPIEDADES
  // ============================================================================

  /// Lista de widgets que forman el contenido del formulario
  /// Ejemplo: [TextFormField(...), DropdownButtonFormField(...), ...]
  final List<Widget> children;

  /// Callback cuando se presiona Cancelar
  final VoidCallback? onCancel;

  /// Callback cuando se presiona Guardar
  final VoidCallback? onSave;

  /// Texto del botón Guardar (por defecto: "Guardar")
  final String? saveButtonText;

  /// Texto del botón Cancelar (por defecto: "Cancelar")
  final String? cancelButtonText;

  /// GlobalKey del formulario para validación
  final GlobalKey<FormState> formKey;

  /// Si es true, muestra los botones Cancelar/Guardar
  /// Si es false, solo muestra el contenido
  final bool showButtons;

  /// Padding personalizado (si no se proporciona, usa el estándar)
  final EdgeInsets? padding;

  // ============================================================================
  // 🏗️ CONSTRUCTOR
  // ============================================================================

  const CustomFormContainer({
    super.key,
    required this.children,
    required this.formKey,
    this.onCancel,
    this.onSave,
    this.saveButtonText = "Guardar",
    this.cancelButtonText = "Cancelar",
    this.showButtons = true,
    this.padding,
  });

  // ============================================================================
  // 🎨 BUILD - ESTRUCTURA PRINCIPAL
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Permite scroll si el contenido es muy largo
      child: Container(
        // Padding interno (usa el personalizado o el estándar)
        padding: padding ?? FormStyles.containerPadding,

        // Decoración del contenedor
        decoration: BoxDecoration(
          // Color de fondo blanco
          color: Themes.white,

          // Bordes redondeados
          borderRadius: BorderRadius.circular(FormStyles.borderRadius),

          // Sombra sutil para profundidad
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        // Contenido del contenedor
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ========== CAMPOS DEL FORMULARIO ==========
              ...children,

              // ========== BOTONES (si showButtons es true) ==========
              if (showButtons) ...[
                // Espaciado antes de los botones
                const SizedBox(height: FormStyles.sectionSpacing),

                // Fila de botones
                _buildButtonsRow(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // 🔘 BOTONES - Cancelar y Guardar
  // ============================================================================

  /// Construye la fila de botones
  ///
  /// Estructura:
  /// ┌─────────────────────────────────┐
  /// │ [Cancelar]    [Guardar]         │
  /// └─────────────────────────────────┘
  ///
  /// - Botón izquierdo: Cancelar (OutlinedButton)
  /// - Botón derecho: Guardar (ElevatedButton)
  Widget _buildButtonsRow(BuildContext context) {
    return Row(
      children: [
        // ========== BOTÓN CANCELAR ==========
        Expanded(
          child: OutlinedButton(
            // Acción al presionar
            onPressed: onCancel ?? () => Navigator.pop(context),

            // Estilo del botón (usa FormStyles)
            style: FormStyles.buildSecondaryButtonStyle(),

            // Texto del botón
            child: Text(cancelButtonText!),
          ),
        ),

        // Espaciado entre botones
        const SizedBox(width: 12),

        // ========== BOTÓN GUARDAR ==========
        Expanded(
          child: ElevatedButton(
            // Acción al presionar
            onPressed: onSave,

            // Estilo del botón (usa FormStyles)
            style: FormStyles.buildPrimaryButtonStyle(),

            // Texto del botón
            child: Text(
              saveButtonText!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
