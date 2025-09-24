// register.screen.dart
// Pantalla de registro con estructura organizada y componentes separados
// Propósito: Mostrar formulario de registro y manejar lógica de autenticación
// Autor: [Tu nombre]
// Última modificación: [Fecha]
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/auth_error_handler.dart';
import 'package:finances/presentations/screens/Auth/LoginScreen.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finances/presentations/widgets/custom_scaffold.dart';
import 'package:finances/presentations/screens/terms_acceptance.screen.dart';

// Importamos los componentes especializados que organizan la UI

import 'package:finances/presentations/screens/auth/widgets/register_actions.dart';
import 'package:finances/presentations/screens/auth/widgets/register_divider.dart';
import 'package:finances/presentations/screens/auth/widgets/register_form.dart';
import 'package:finances/presentations/screens/auth/widgets/register_terms.dart';

/// Pantalla de registro que permite a los usuarios crear una nueva cuenta
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

/// Estado de la pantalla de registro
class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Controladores de texto para cada campo del formulario
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Estados de visibilidad para las contraseñas
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Estado de carga para el botón de registro
  bool _isLoading = false;

  // Estado para el checkbox de términos y condiciones
  bool _agreeTerms = false;

  // Clave global para validar el formulario
  final _formKey = GlobalKey<FormState>();

  /// Muestra un SnackBar con un mensaje de feedback al usuario
  ///
  /// [message] - Mensaje a mostrar
  /// [color] - Color de fondo del SnackBar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  /// Lógica principal de registro de usuario
  ///
  /// Valida el formulario, verifica términos y realiza el registro
  Future<void> _register() async {
    // Prevenir múltiples registros simultáneos
    if (_isLoading) return;

    // Validar formulario antes de proceder
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authNotifier = ref.read(authProvider.notifier);

    try {
      // Verificar aceptación de términos
      if (!_agreeTerms) {
        _showSnackBar(ErrorStrings.termsNotAccepted, Colors.red);
        return;
      }

      // Llamada al provider para crear la cuenta
      await authNotifier.signUp(
        _nameController.text.trim(),
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Cerrar sesión inmediatamente después del registro
      await FirebaseAuth.instance.signOut();

      // Mostrar feedback de éxito
      _showSnackBar(ErrorStrings.registrationSuccess, Colors.green);

      // Redirigir a la pantalla de login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Manejar errores específicos de Firebase
      _showSnackBar(AuthErrorHandler.handle(e), Colors.red);
    } catch (e) {
      // Manejar errores inesperados
      _showSnackBar('Ocurrió un error inesperado.', Colors.red);
    } finally {
      // Restablecer estado de carga
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Inicia sesión con Google
  ///
  /// Maneja el flujo de autenticación con Google y redirige según sea necesario
  Future<void> _signInWithGoogle() async {
    try {
      final authNotifier = ref.read(authProvider.notifier);
      final isNewUser = await authNotifier.signInWithGoogle();

      // Si es nuevo usuario, redirigir a términos de uso
      if (isNewUser) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TermsAcceptanceScreen()),
        );
      } else {
        // Si ya existe, mostrar mensaje
        _showSnackBar("Su cuenta ya se encuentra registrada.", Colors.blue);
      }
    } catch (e) {
      // Mostrar errores de autenticación
      _showSnackBar(e.toString(), Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(25, 50, 25, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40.0),
              topRight: Radius.circular(40.0),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Título de la pantalla
                const Text(
                  'Registrarse',
                  style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.w900,
                    color: Themes.degradientLight,
                  ),
                ),
                const SizedBox(height: 40),

                // Componente de formulario con todos los campos
                RegisterForm(
                  nameController: _nameController,
                  usernameController: _usernameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  isPasswordVisible: _isPasswordVisible,
                  isConfirmPasswordVisible: _isConfirmPasswordVisible,
                  onPasswordVisibilityToggle: () => setState(
                    () => _isPasswordVisible = !_isPasswordVisible,
                  ),
                  onConfirmPasswordVisibilityToggle: () => setState(
                    () =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                  ),
                ),

                // Componente de términos y condiciones
                RegisterTerms(
                  agreed: _agreeTerms,
                  onAgreeChanged: (value) =>
                      setState(() => _agreeTerms = value),
                ),

                // Componente con botones de acción
                RegisterActions(
                  isLoading: _isLoading,
                  onRegister: _register,
                  onGoogleSignIn: _signInWithGoogle,
                  onLoginTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),

                // Separador visual
                const RegisterDivider(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
