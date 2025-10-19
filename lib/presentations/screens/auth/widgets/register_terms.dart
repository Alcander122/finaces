// register_terms.dart
// Componente que maneja el checkbox de términos y condiciones
// Propósito: Encapsular la lógica y UI relacionada con la aceptación de términos
// Autor: [Tu nombre]
// Última modificación: [Fecha]

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/presentations/theme/themes.dart';

/// Componente que muestra el checkbox para aceptar términos y políticas
///
/// Maneja la lógica de aceptación y muestra los diálogos de términos y políticas
class RegisterTerms extends StatelessWidget {
  const RegisterTerms({
    required this.agreed,
    required this.onAgreeChanged,
    super.key,
  });

  /// Indica si el usuario ha aceptado los términos
  final bool agreed;

  /// Callback cuando el estado del checkbox cambia
  final ValueChanged<bool> onAgreeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: agreed,
          onChanged: (value) => onAgreeChanged(value ?? false),
          activeColor: Themes.degradientLight,
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              children: [
                const TextSpan(text: 'Al registrarte, aceptas nuestros '),
                _buildTermsLink(
                    'Términos y Condiciones', () => _showTermsDialog(context)),
                const TextSpan(text: ' y '),
                _buildTermsLink('Política de Privacidad',
                    () => _showPrivacyPolicyDialog(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Crea un enlace subrayado para términos o política de privacidad
  TextSpan _buildTermsLink(String text, VoidCallback onTap) {
    return TextSpan(
      text: text,
      style: TextStyle(
        color: Themes.degradientLight,
        decoration: TextDecoration.underline,
      ),
      recognizer: TapGestureRecognizer()..onTap = onTap,
    );
  }

  /// Muestra el diálogo con los términos y condiciones
  void _showTermsDialog(BuildContext context) {
    _showDialog(
      context,
      title: ErrorStrings.termsAndConditionsTitle,
      content: ErrorStrings.termsAndConditionsContent,
    );
  }

  /// Muestra el diálogo con la política de privacidad
  void _showPrivacyPolicyDialog(BuildContext context) {
    _showDialog(
      context,
      title: ErrorStrings.privacyPolicyTitle,
      content: ErrorStrings.privacyPolicyContent,
    );
  }

  /// Muestra un diálogo genérico con título y contenido
  void _showDialog(BuildContext context,
      {required String title, required String content}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
