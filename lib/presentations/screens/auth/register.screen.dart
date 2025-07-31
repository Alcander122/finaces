import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/services/user_service.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/auth_error_handler.dart';
import 'package:finances/presentations/screens/home/home_screen.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:flutter/material.dart';
import 'LoginScreen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:icons_plus/icons_plus.dart'; // This import provides the Logos class for social icons
import 'package:finances/presentations/widgets/custom_scaffold.dart';
import 'package:finances/presentations/screens/terms_acceptance.screen.dart'; // Importar la nueva pantalla

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores de los campos
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  // Estados de visibilidad de contraseñas
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false; // Estado de carga
  final _formSignupKey = GlobalKey<FormState>();
  bool agreePersonalData = false;

  // Muestra SnackBars con mensajes
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // Lógica de registro con validaciones
  void register(BuildContext context) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      if (_formSignupKey.currentState!.validate() && agreePersonalData) {
        final userService = UserService();
        await userService.registerUser(
          name: _nameController.text,
          displayName: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        _showSnackBar(ErrorStrings.registrationSuccess, Colors.green);
      } else if (!agreePersonalData) {
        _showSnackBar(ErrorStrings.termsNotAccepted, Colors.red);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = AuthErrorHandler.handle(e);
      _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      _showSnackBar('An unexpected error occurred.', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      // LayoutBuilder permite obtener el tamaño de la pantalla
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              // Garantiza que el contenido tenga al menos la altura de la pantalla
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                // Permite que Column use el espacio mínimo necesario sin desbordarse
                child: Column(
                  children: [
                    const SizedBox(height: 40), // Espacio superior opcional
                    // Contenedor de formulario sin usar Expanded
                    Container(
                      padding:
                          const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40.0),
                          topRight: Radius.circular(40.0),
                        ),
                      ),
                      child: Form(
                        key: _formSignupKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Título
                            Text(
                              'Registrarse',
                              style: TextStyle(
                                fontSize: 30.0,
                                fontWeight: FontWeight.w900,
                                color: Themes.degradientLight,
                              ),
                            ),
                            const SizedBox(height: 40.0),
                            // Nombre Completo
                            TextFormField(
                              controller: _nameController,
                              validator: (value) => value?.isEmpty ?? true
                                  ? ErrorStrings.requiredField
                                  : null,
                              decoration: _inputDecoration('Nombre Completo'),
                            ),
                            const SizedBox(height: 25.0),
                            // Nombre Usuario
                            TextFormField(
                              controller: _usernameController,
                              validator: (value) => value?.isEmpty ?? true
                                  ? ErrorStrings.requiredField
                                  : null,
                              decoration: _inputDecoration('Nombre Usuario'),
                            ),
                            const SizedBox(height: 25.0),
                            // Correo
                            TextFormField(
                              controller: _emailController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return ErrorStrings.requiredField;
                                }
                                if (!_validateEmail(value)) {
                                  return ErrorStrings.invalidEmail;
                                }
                                return null;
                              },
                              decoration: _inputDecoration('Correo'),
                            ),
                            const SizedBox(height: 25.0),
                            // Contraseña
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              validator: (value) => value?.isEmpty ?? true
                                  ? ErrorStrings.requiredField
                                  : null,
                              decoration:
                                  _inputDecoration('Contraseña').copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(_isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () => setState(() =>
                                      _isPasswordVisible = !_isPasswordVisible),
                                ),
                              ),
                            ),
                            const SizedBox(height: 25.0),
                            // Confirmar contraseña
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_isConfirmPasswordVisible,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return ErrorStrings.requiredField;
                                }
                                if (value != _passwordController.text) {
                                  return ErrorStrings.passwordMismatch;
                                }
                                return null;
                              },
                              decoration:
                                  _inputDecoration('Confirmar Contraseña')
                                      .copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(() =>
                                      _isConfirmPasswordVisible =
                                          !_isConfirmPasswordVisible),
                                ),
                              ),
                            ),
                            const SizedBox(height: 25.0),
                            // Checkbox de términos (minimalista pero con enlaces a términos completos)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: agreePersonalData,
                                  onChanged: (value) => setState(
                                      () => agreePersonalData = value ?? false),
                                  activeColor: Themes.degradientLight,
                                ),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                          color: Colors.black87, fontSize: 14),
                                      children: [
                                        const TextSpan(
                                            text:
                                                'Al registrarte, aceptas nuestros '),
                                        WidgetSpan(
                                          child: GestureDetector(
                                            onTap: () =>
                                                _showTermsDialog(context),
                                            child: Text(
                                              'Términos y Condiciones',
                                              style: TextStyle(
                                                color: Themes.degradientLight,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const TextSpan(text: ' y '),
                                        WidgetSpan(
                                          child: GestureDetector(
                                            onTap: () =>
                                                _showPrivacyPolicyDialog(
                                                    context),
                                            child: Text(
                                              'Política de Privacidad',
                                              style: TextStyle(
                                                color: Themes.degradientLight,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25.0),
                            // Botón de registro
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => register(context),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text('Registrar'),
                              ),
                            ),
                            const SizedBox(height: 30.0),
                            // Línea separadora
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.withValues(alpha: 0.5),
                                    thickness: 0.7,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text('Iniciar sesión',
                                      style: TextStyle(color: Colors.black45)),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.withValues(alpha: 0.5),
                                    thickness: 0.7,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30.0),
                            // Iconos redes sociales
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
                                          // MODIFICADO: Ahora signInWithGoogle devuelve si es nuevo usuario
                                          final isNewUser = await authNotifier
                                              .signInWithGoogle();

                                          if (isNewUser) {
                                            // Si es usuario nuevo, mostrar pantalla de términos
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    TermsAcceptanceScreen(),
                                              ),
                                            );
                                          } else {
                                            // Usuario existente puede ir directamente
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const HomeScreen()),
                                              (route) => false,
                                            );
                                          }
                                        } catch (e) {
                                          _showSnackBar(
                                              e.toString(), Colors.red);
                                        }
                                      },
                                      child: Logo(Logos.google),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 25.0),
                            // Link a Login
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('¿Ya tienes una cuenta? ',
                                    style: TextStyle(color: Colors.black45)),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  ),
                                  child: Text(
                                    'Inicia sesión',
                                    style: TextStyle(
                                      color: Themes.degradientLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Mostrar diálogo con términos y condiciones
  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ErrorStrings.termsAndConditionsTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ErrorStrings.termsAndConditionsContent,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
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

  // Mostrar diálogo con política de privacidad
  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ErrorStrings.privacyPolicyTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ErrorStrings.privacyPolicyContent,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
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

  // Decoración reutilizable para inputs
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      hintText: 'Ingresa $label',
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

  // Validación de correo con regex
  bool _validateEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }
}
