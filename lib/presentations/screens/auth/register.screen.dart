import 'package:finances/core/data/services/user_service.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'LoginScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _validateEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  void register(BuildContext context) async {
    if (!_validateEmail(_emailController.text)) {
      _showSnackBar('Correo electrónico no válido', Colors.red);
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Las contraseñas no coinciden', Colors.red);
      return;
    }

    try {
      final userService = UserService();
      await userService.registerUser(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      print("Usuario registrado con éxito");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );

      _showSnackBar(
          'Registro exitoso. Por favor, inicia sesión.', Colors.green);
    } catch (e) {
      print("Error en el registro: $e");
      String errorMessage = 'Error al registrar usuario';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'El correo electrónico ya está en uso';
            break;
          case 'invalid-email':
            errorMessage = 'El correo electrónico no es válido';
            break;
          case 'weak-password':
            errorMessage = 'La contraseña es demasiado débil';
            break;
          default:
            errorMessage = 'Error inesperado. Intenta de nuevo.';
        }
      }

      _showSnackBar(errorMessage, Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20.0),
              Image.asset('assets/images/Logo1.png', width: 200, height: 200),
              const SizedBox(height: 20),
              _buildTextField(_nameController, "Ingresa tu nombre"),
              _buildTextField(
                  _emailController, "Ingresa tu correo electrónico"),
              _buildTextField(
                  _passwordController, "Ingresa tu contraseña", true),
              _buildTextField(
                  _confirmPasswordController, "Confirma tu contraseña", true),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () => register(context),
                  child: const Text('Registrar')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () =>
                    {Navigator.pushNamed(context, AppRoutes.login)},
                child: const Text('Volver al Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      [bool isPassword = false]) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      obscureText: isPassword,
    );
  }
}
