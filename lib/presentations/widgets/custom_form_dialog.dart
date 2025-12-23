// 📌 custom_form_dialog.dart
// ============================================================================
// ARCHIVO: presentations/widgets/custom_form_dialog.dart
// PROPÓSITO: Diálogo personalizado con diseño como "Nuevo Egreso"
// DESCRIPCIÓN: Header azul oscuro + Fondo azul claro + Contenedor blanco
// ============================================================================

import 'package:flutter/material.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/widgets/form_styles.dart';

class CustomFormDialog extends StatelessWidget {
  // ============================================================================
  // 📋 PROPIEDADES
  // ============================================================================

  /// Título del diálogo (ej: "Nuevo Ingreso")
  final String title;

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

  // ============================================================================
  // 🏗️ CONSTRUCTOR
  // ============================================================================

  const CustomFormDialog({
    super.key,
    required this.title,
    required this.children,
    required this.formKey,
    this.onCancel,
    this.onSave,
    this.saveButtonText = "Guardar",
    this.cancelButtonText = "Cancelar",
    this.showButtons = true,
  });

  // ============================================================================
  // 🎨 BUILD - ESTRUCTURA PRINCIPAL
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // ⭐ Sin padding para ocupar todo el espacio
      insetPadding: EdgeInsets.zero,

      // Sin forma predefinida, usaremos Container
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),

      // Contenedor principal con fondo azul claro
      child: Container(
        // Fondo azul claro (gradiente)
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Themes.degradientDark, Themes.degradientLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        // Estructura en columna
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // ========== SECCIÓN 1: HEADER AZUL OSCURO ==========
            _buildHeader(context),

            // ========== SECCIÓN 2: CONTENEDOR BLANCO CON CONTENIDO ==========
            Expanded(
              child: _buildWhiteContainer(context),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 🎨 HEADER - Título + Botón Cerrar (Azul Oscuro)
  // ============================================================================

  /// Construye el header del diálogo con fondo azul oscuro
  ///
  /// Estructura:
  /// ┌─────────────────────────────────┐
  /// │ Título del Diálogo    [X Cerrar]│ ← Fondo azul oscuro
  /// └─────────────────────────────────┘
  Widget _buildHeader(BuildContext context) {
    return Container(
      // Padding interno
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

      // ⭐ Fondo azul oscuro (diferente al fondo del formulario)
      decoration: BoxDecoration(
        color: Themes.degradientDark, // Azul oscuro
      ),

      // Contenido del header: Título + Botón Cerrar
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Título del diálogo
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Botón cerrar (X)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 📝 CONTENEDOR BLANCO - Formulario con Scroll
  // ============================================================================

  /// Construye el contenedor blanco redondeado con el formulario
  ///
  /// Características:
  /// - Fondo blanco
  /// - Bordes redondeados
  /// - Padding interno
  /// - Scroll automático
  Widget _buildWhiteContainer(BuildContext context) {
    return Container(
      // Margen alrededor del contenedor blanco
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

      // Decoración: fondo blanco con bordes redondeados
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // ⭐ Bordes redondeados
      ),

      // Contenido del contenedor
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // ========== CONTENIDO DEL FORMULARIO ==========
          Expanded(
            child: _buildContent(),
          ),

          // ========== BOTONES (si showButtons es true) ==========
          if (showButtons) _buildButtonsSection(context),
        ],
      ),
    );
  }

  // ============================================================================
  // 📝 CONTENIDO - Formulario con Scroll
  // ============================================================================

  /// Construye la sección de contenido con scroll automático
  ///
  /// Características:
  /// - Scroll vertical si el contenido es muy largo
  /// - Form para validación
  /// - Padding interno
  Widget _buildContent() {
    return SingleChildScrollView(
      // Scroll vertical automático
      child: Padding(
        // Padding interno del contenido
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),

        // Formulario para validación
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,

            // Los campos del formulario van aquí
            // Ejemplo: [TextFormField(...), DropdownButtonFormField(...), ...]
            children: children,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // 🔘 BOTONES - Cancelar y Guardar
  // ============================================================================

  /// Construye la sección de botones (Cancelar y Guardar)
  ///
  /// Estructura:
  /// ┌─────────────────────────────────┐
  /// │ [Cancelar]    [Guardar]         │
  /// └─────────────────────────────────┘
  Widget _buildButtonsSection(BuildContext context) {
    return Padding(
      // Padding alrededor de los botones
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

      // Fila con dos botones
      child: _buildButtonsRow(context),
    );
  }

  /// Construye la fila de botones
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

            // Estilo del botón
            style: FormStyles.buildSecondaryButtonStyle(),

            // Texto del botón
            child: Text(
              cancelButtonText!,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),

        // Espaciado entre botones
        const SizedBox(width: 12),

        // ========== BOTÓN GUARDAR ==========
        Expanded(
          child: ElevatedButton(
            // Acción al presionar
            onPressed: onSave,

            // Estilo del botón
            style: FormStyles.buildPrimaryButtonStyle(),

            // Texto del botón
            child: Text(
              saveButtonText!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
