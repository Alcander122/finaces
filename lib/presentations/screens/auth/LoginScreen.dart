import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/presentations/screens/SecondScreen.dart';
import 'package:finances/presentations/screens/auth/register.screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _validateFields() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
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
              const SizedBox(height: 4),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Ingresa tu correo electrónico',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Ingresa tu contraseña',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!_validateFields()) return;

                    try {
                      await ref.read(authProvider.notifier).signIn(
                            _emailController.text,
                            _passwordController.text,
                          );

                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SecondScreen()),
                        );
                      }
                    } catch (e) {
                      debugPrint(
                          'Error al iniciar sesión: $e'); // Verificación de errores en consola

                      String errorMessage = 'Error al iniciar sesión';
                      if (e is FirebaseAuthException) {
                        switch (e.code) {
                          case 'user-not-found':
                            errorMessage = 'Usuario no encontrado';
                            break;
                          case 'wrong-password':
                            errorMessage = 'Contraseña incorrecta';
                            break;
                          case 'invalid-email':
                            errorMessage = 'Correo electrónico inválido';
                            break;
                          case 'invalid-credential':
                            errorMessage =
                                'Credenciales inválidas o han expirado';
                            break;
                          default:
                            errorMessage =
                                'Ocurrió un error inesperado. Por favor, intenta de nuevo.';
                        }
                      } else {
                        errorMessage =
                            'Ocurrió un error inesperado. Por favor, intenta de nuevo.';
                      }

                      if (mounted) {
                        debugPrint(
                            'Mostrando SnackBar: $errorMessage'); // Verificación de cuando se muestra el SnackBar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        debugPrint(
                            'No se mostró el SnackBar porque el widget no está montado.');
                      }
                    }
                  },
                  child: const Text('Iniciar sesión'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterScreen()));
                  },
                  child: const Text('Ir a registro'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
