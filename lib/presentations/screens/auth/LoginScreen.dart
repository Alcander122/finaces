// lib/presentations/screens/Auth/LoginScreen.dart

import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/services/BiometricAuthService.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/auth_error_handler.dart';
import 'package:finances/presentations/screens/Auth/register.screen.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/widgets/custom_scaffold.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formSignInKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Valida que los campos no estén vacíos
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

  /// Maneja y formatea los errores de Firebase Auth
  String _handleError(Object error) {
    if (error is FirebaseAuthException) {
      return AuthErrorHandler.handle(error);
    }
    return error.toString();
  }

  /// Muestra un SnackBar con el mensaje de error
  void _showErrorFeedback(String message) {
    if (!mounted) return;
    UIHelpers.showErrorSnackBar(context: context, message: message);
  }

  /// Maneja el proceso de login con email y contraseña
  Future<void> _performLogin() async {
    if (!_validateFields() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

      if (mounted) {
        UIHelpers.showSuccessSnackBarNew(
          context: context,
          message: 'Inicio de sesión exitoso',
        );

        // Verificar si la biometría está activada para decidir la redirección
        final isBiometricEnabled =
            await BiometricAuthService().isBiometricEnabled();

        if (isBiometricEnabled) {
          // Si la biometría está activada, ir al splash para verificarla
          Navigator.pushReplacementNamed(context, '/');
        } else {
          // Si no está activada, ir directamente al home
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      }
    } catch (e) {
      debugPrint('Error en login: $e');
      _showErrorFeedback(_handleError(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el estado de autenticación
    final authState = ref.watch(authProvider);

    // ✅ NUEVO: COMENTAMOS LA REDIRECCIÓN AUTOMÁTICA
    // Antes, esto redirigía directamente al Home si el usuario estaba autenticado.
    // Eso rompía el flujo de la biometría, porque saltaba el SplashScreen.
    // Ahora, controlamos la navegación manualmente en _performLogin.
    /*
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState.isAuthenticated) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    });
    */

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
                      // Mostrar indicador de carga si está autenticando
                      if (authState.isLoading || _isLoading)
                        const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 20),
                            Text('Iniciando sesión...'),
                          ],
                        )
                      else
                        Column(
                          children: [
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
                              decoration: _inputDecoration(
                                  'Correo', 'ejemplo@dominio.com'),
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
                                if (value.length < 6)
                                  return "Mínimo 6 caracteres";
                                return null;
                              },
                              decoration:
                                  _inputDecoration('Contraseña', '••••••••'),
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
                          ],
                        ),
                      const SizedBox(height: 25.0),
                      _buildDivider(),
                      const SizedBox(height: 25.0),
                      // Botón de login con Google
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              if (_isLoading) return;
                              try {
                                setState(() => _isLoading = true);
                                final authNotifier =
                                    ref.read(authProvider.notifier);
                                final isNewUser =
                                    await authNotifier.signInWithGoogle();

                                // Si es un usuario nuevo, mostramos un diálogo
                                if (isNewUser && mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Cuenta no registrada'),
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
                                }

                                // ✅ NUEVO: Después de un login con Google, también redirigimos al SplashScreen
                                if (mounted) {
                                  Navigator.pushReplacementNamed(context, '/');
                                }
                              } catch (e) {
                                _showErrorFeedback(e.toString());
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                            child: Logo(Logos.google),
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
