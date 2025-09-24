// LoginScreen.dart (CORREGIDO Y COMENTADO)
// presentations/screens/auth/login_screen.dart
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/tutorial_provider.dart';
import 'package:finances/core/data/services/BiometricAuthService.dart';
import 'package:finances/core/data/utils/form_validators.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/auth_error_handler.dart';
import 'package:finances/presentations/screens/auth/register.screen.dart';
import 'package:finances/presentations/screens/auth/widgets/forgot_password_dialog.dart';
import 'package:finances/presentations/screens/auth/widgets/login_divider.dart';
import 'package:finances/presentations/screens/auth/widgets/register_link.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/widgets/custom_scaffold.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:finances/routes/app_routes.dart'; // Importamos las rutas de la app

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  // Estados de visibilidad de contraseñas
  bool _isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricStatus() async {
    final enabled = await BiometricAuthService().isBiometricEnabled();
    if (mounted) {
      setState(() => _biometricEnabled = enabled);
    }
  }

  Future<void> _loginWithCredentials() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

      // ✅ CLAVE: Después de login exitoso, verificamos si el tutorial ya fue visto
      final tutorialSeen = await ref.read(tutorialProvider.future);

      if (mounted) {
        UIHelpers.showSuccessSnackBarNew(
          context: context,
          message: 'Inicio de sesión exitoso',
        );

        // Si el tutorial NO ha sido visto, mostramos el tutorial
        // Si ya fue visto, vamos directo a home
        if (tutorialSeen) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.tutorial);
        }
      }
    } catch (e) {
      _showErrorFeedback(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithBiometrics() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final success = await BiometricAuthService().authenticate(context);
      if (success && mounted) {
        // ✅ CLAVE: Después de login biométrico, verificamos si el tutorial ya fue visto
        final tutorialSeen = await ref.read(tutorialProvider.future);
        if (tutorialSeen) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.tutorial);
        }
      }
    } catch (e) {
      _showErrorFeedback("Error con la autenticación biométrica");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final isNewUser =
          await ref.read(authProvider.notifier).signInWithGoogle();
      if (isNewUser && mounted) {
        _showNewUserDialog();
      }

      // ✅ CLAVE: Después de login con Google, verificamos si el tutorial ya fue visto
      final tutorialSeen = await ref.read(tutorialProvider.future);
      if (mounted) {
        if (tutorialSeen) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.tutorial);
        }
      }
    } catch (e) {
      _showErrorFeedback(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNewUserDialog() {
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
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showErrorFeedback(Object error) {
    if (!mounted) return;
    String message;
    if (error is FirebaseAuthException) {
      message = AuthErrorHandler.handle(error);
    } else {
      message = error.toString();
    }
    UIHelpers.showErrorSnackBar(context: context, message: message);
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => ForgotPasswordDialog(
        onSendPasswordReset: _sendPasswordResetEmail,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    if (email.isEmpty) {
      UIHelpers.showErrorSnackBar(
        context: context,
        message: ErrorStrings.requiredField,
      );
      return;
    }
    try {
      setState(() => _isLoading = true);
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        UIHelpers.showSuccessSnackBarNew(
          context: context,
          message: ErrorStrings.passwordResetSuccess,
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = _handleForgotPasswordError(e);
      if (mounted) {
        _showErrorFeedback(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorFeedback(ErrorStrings.unexpectedError);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _handleForgotPasswordError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return ErrorStrings.userNotFound;
      case 'invalid-email':
        return ErrorStrings.invalidEmail;
      case 'too-many-requests':
        return ErrorStrings.passwordResetTooManyRequests;
      default:
        return ErrorStrings.unexpectedError;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
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
                  key: _formKey,
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
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: FormValidators.validateEmail,
                              decoration: _inputDecoration(
                                  'Correo', 'ejemplo@dominio.com'),
                            ),
                            const SizedBox(height: 25.0),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              validator: (value) => value?.isEmpty ?? true
                                  ? ErrorStrings.requiredField
                                  : null,
                              decoration: _inputDecoration(
                                      'Contraseña', 'Ingrese su contraseña')
                                  .copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(_isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () => setState(() =>
                                      _isPasswordVisible = !_isPasswordVisible),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15.0),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                child: Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(
                                    color: Themes.degradientLight,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loginWithCredentials,
                                child: const Text('Ingresar'),
                              ),
                            ),
                            if (_biometricEnabled)
                              Padding(
                                padding: const EdgeInsets.only(top: 15.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Themes.primary,
                                    ),
                                    onPressed: _loginWithBiometrics,
                                    icon: const Icon(Icons.fingerprint,
                                        color: Colors.white),
                                    label: const Text(
                                      "Ingresar con huella",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 25.0),
                      const LoginDivider(),
                      const SizedBox(height: 25.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: _handleGoogleSignIn,
                            child: Logo(Logos.google),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25.0),
                      const RegisterLink(),
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
}
