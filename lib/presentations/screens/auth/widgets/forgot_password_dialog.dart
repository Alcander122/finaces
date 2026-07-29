// widgets/forgot_password_dialog.dart
import 'package:finances/presentations/theme/themes.dart';
import 'package:flutter/material.dart';

class ForgotPasswordDialog extends StatelessWidget {
  final void Function(String email) onSendPasswordReset;

  const ForgotPasswordDialog({super.key, required this.onSendPasswordReset, required void Function() onCancel});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    return AlertDialog(
      title: Text('Restablecer contraseña',
          style: TextStyle(color: Themes.degradientLight)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: emailController,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              labelStyle: const TextStyle(color: Colors.black54),
              hintText: 'ejemplo@dominio.com',
              hintStyle: const TextStyle(color: Colors.black38),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child:
              Text('Cancelar', style: TextStyle(color: Themes.degradientLight)),
        ),
        TextButton(
          onPressed: () => onSendPasswordReset(emailController.text.trim()),
          child:
              Text('Enviar', style: TextStyle(color: Themes.degradientLight)),
        ),
      ],
    );
  }
}
