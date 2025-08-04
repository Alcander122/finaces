import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/auth_error_handler.dart';
import 'package:finances/presentations/screens/Auth/register.screen.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/widgets/custom_scaffold.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:finances/utils/ui_helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';

/// Pantalla de login para autenticar al usuario mediante correo y contraseña.
/// También incorpora el inicio de sesión con Google.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends ConsumerState<LoginScreen> {
  // Controladores para los campos de entrada
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Clave para validar el formulario
  final GlobalKey<FormState> _formSignInKey = GlobalKey<FormState>();

  /// Verifica si los campos están llenos.
  bool _validateFields() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      UIHelpers.showErrorSnackBar(
        context: context,
        message: ErrorStrings.requiredField,
      );
      return false;
    }
    return true;
  }

  /// Muestra un SnackBar con un mensaje y color.
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  /// Maneja errores y retorna un mensaje amigable.
  String _handleError(Object error) {
    if (error is FirebaseAuthException) {
      return AuthErrorHandler.handle(error);
    }
    return ErrorStrings.unexpectedError;
  }

  /// Muestra feedback de error al usuario.
  void _showErrorFeedback(String message) {
    if (!mounted) return;
    UIHelpers.showErrorSnackBar(context: context, message: message);
  }

  /// Realiza el login con email y contraseña.
  Future<void> _performLogin() async {
    if (!_validateFields()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref.read(authProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

      Navigator.pop(context); // Cierra el diálogo de carga

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Error en login: $e');
      _showErrorFeedback(_handleError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          const Expanded(flex: 1, child: SizedBox(height: 10)),
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formSignInKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Inicie sesión',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w900,
                          color: Themes.degradientLight,
                        ),
                      ),
                      const SizedBox(height: 40.0),

                      // Input de email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return ErrorStrings.requiredField;
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return ErrorStrings.invalidEmail;
                          }
                          return null;
                        },
                        decoration:
                            _inputDecoration('Correo', 'ejemplo@dominio.com'),
                      ),
                      const SizedBox(height: 25.0),

                      // Input de contraseña
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        obscuringCharacter: '•',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return ErrorStrings.requiredField;
                          }
                          if (value.length < 6) return "Mínimo 6 caracteres";
                          return null;
                        },
                        decoration: _inputDecoration('Contraseña', '••••••••'),
                      ),
                      const SizedBox(height: 25.0),

                      // Botón de ingresar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _performLogin,
                          child: const Text('Ingresar'),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      _buildDivider(),
                      const SizedBox(height: 25.0),

                      // Botón de login con Google
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Consumer(
                            builder: (context, ref, _) {
                              return GestureDetector(
                                onTap: () async {
                                  try {
                                    final authNotifier =
                                        ref.read(authProvider.notifier);
                                    final isNewUser =
                                        await authNotifier.signInWithGoogle();
                                    if (isNewUser) {
                                      // Mostrar mensaje y redirigir a registro
                                      if (!mounted) return;
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text(
                                              'Cuenta no registrada'),
                                          content: const Text(
                                              'La cuenta no se encuentra registrada, será redireccionado al registro para crear la cuenta.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          const RegisterScreen()),
                                                );
                                              },
                                              child: const Text('Aceptar'),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      // Redirige a home
                                      if (mounted) {
                                        Navigator.pushReplacementNamed(
                                            context, AppRoutes.home);
                                      }
                                    }
                                  } catch (e) {
                                    _showSnackBar(e.toString(), Colors.red);
                                  }
                                },
                                child: Logo(Logos.google),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 25.0),
                      _buildRegisterSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sección de divider entre login tradicional y social login
  Widget _buildDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Divider(
            thickness: 0.7,
            color: Colors.grey.withAlpha(50),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('Login', style: TextStyle(color: Colors.black45)),
        ),
        Expanded(
          child: Divider(
            thickness: 0.7,
            color: Colors.grey.withAlpha(50),
          ),
        ),
      ],
    );
  }

  /// Redirige al usuario a la pantalla de registro
  Widget _buildRegisterSection() {
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

  /// Estilo de los inputs del formulario
  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      label: Text(label),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black26),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black12),
      ),
    );
  }
}
