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
  // Controladores para capturar el correo y la contraseña ingresados por el usuario.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Clave global para validar el formulario.
  final GlobalKey<FormState> _formSignInKey = GlobalKey<FormState>();

  /// Valida que los campos de correo y contraseña no estén vacíos.
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

  /// Muestra un SnackBar con el mensaje y color correspondiente.
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  /// Maneja y retorna el mensaje de error a partir de una excepción.
  String _handleError(Object error) {
    if (error is FirebaseAuthException) {
      return AuthErrorHandler.handle(error);
    }
    return ErrorStrings.unexpectedError;
  }

  /// Muestra el feedback de error al usuario.
  void _showErrorFeedback(String message) {
    if (!mounted) return;
    UIHelpers.showErrorSnackBar(context: context, message: message);
  }

  /// Función que realiza el inicio de sesión mediante el método definido en AuthProvider.
  Future<void> _performLogin() async {
    if (!_validateFields()) return;

    try {
      // Se invoca al método signIn del AuthProvider, pasando email y contraseña.
      await ref.read(authProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

      // Si la autenticación es exitosa, navegamos al HomeScreen.
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      debugPrint('Error en login: $e');
      _showErrorFeedback(_handleError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Se quita la flecha de retroceso de la AppBar
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScaffold(
        child: Column(
          children: [
            const Expanded(flex: 1, child: SizedBox(height: 10)),
            Expanded(
              flex: 7,
              child: Container(
                padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  // Bordes redondeados en la parte superior
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
                        // Título de la pantalla.
                        Text(
                          'Inicie sesión',
                          style: TextStyle(
                            fontSize: 30.0,
                            fontWeight: FontWeight.w900,
                            color: Themes.degradientLight,
                          ),
                        ),
                        const SizedBox(height: 40.0),
                        // Campo de texto para ingresar el correo.
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return ErrorStrings.requiredField;
                            }
                            // Expresión regular para validar el correo.
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
                        // Campo para la contraseña.
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
                          decoration:
                              _inputDecoration('Contraseña', '••••••••'),
                        ),
                        const SizedBox(height: 25.0),
                        // Botón de inicio de sesión.
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
                        // Sección para login con redes sociales.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Botón de Facebook (ejemplo visual)
                            Logo(Logos.facebook_f),
                            // Botón para iniciar sesión con Google.
                            Consumer(
                              builder: (context, ref, _) {
                                return GestureDetector(
                                  onTap: () async {
                                    try {
                                      final authNotifier =
                                          ref.read(authProvider.notifier);
                                      await authNotifier.signInWithGoogle();
                                      if (mounted) {
                                        Navigator.pushReplacementNamed(
                                          context,
                                          AppRoutes.home,
                                        );
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
      ),
    );
  }

  /// Método para construir un Divider (separador visual) con texto.
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

  /// Sección que redirige al usuario a la pantalla de registro.
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

  /// Método que define la decoración de los campos de entrada.
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