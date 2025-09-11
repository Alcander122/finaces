// presentations/widgets/auth/register_link.dart
import 'package:finances/presentations/screens/Auth/register.screen.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:flutter/material.dart';

class RegisterLink extends StatelessWidget {
  const RegisterLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿No tienes cuenta?',
            style: TextStyle(color: Colors.black45)),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          child: Text(
            'Registrarse',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Themes.degradientLight,
            ),
          ),
        ),
      ],
    );
  }
}
