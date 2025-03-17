import 'package:finances/core/data/services/user_service.dart';
import 'package:finances/core/errors/handlers/auth_error_handler.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/presentations/screens/auth/LoginScreen.dart';
import 'package:finances/presentations/screens/auth/welcome_screen.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/widgets/custom_scaffold.dart';
import 'package:finances/utils/ui_helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

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
  final _formKey = GlobalKey<FormState>();
  bool _agreeTerms = false;
  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userService = UserService();
      await userService.registerUser(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );

      UIHelpers.showErrorSnackBar(
        context: context,
        message: 'Registro exitoso. Por favor, inicia sesión.',
        duration: const Duration(seconds: 3),
      );
    } on FirebaseAuthException catch (e) {
      UIHelpers.showErrorSnackBar(
        context: context,
        message: AuthErrorHandler.handle(e),
      );
    } catch (e) {
      UIHelpers.showErrorSnackBar(
        context: context,
        message: ErrorStrings.unexpectedError,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  '¡Únete a nuestra comunidad!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: lightColorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Crea tu cuenta en segundos y comienza a gestionar tus finanzas',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre completo',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) => value!.isEmpty
                                ? ErrorStrings.requiredField
                                : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return ErrorStrings.requiredField;
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return ErrorStrings.invalidEmail;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return ErrorStrings.requiredField;
                              }
                              if (value.length < 6) {
                                return 'La contraseña debe tener al menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirmar contraseña',
                              prefixIcon: Icon(Icons.lock),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return ErrorStrings.requiredField;
                              }
                              if (value != _passwordController.text) {
                                return ErrorStrings.passwordMismatch;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Checkbox(
                                value: _agreeTerms,
                                onChanged: (value) => setState(
                                  () => _agreeTerms = value!,
                                ),
                              ),
                              const Expanded(
                                child: Text(
                                  'Acepto los términos y condiciones y política de privacidad',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _registerUser,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Crear cuenta',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const DividerWithText(text: 'O regístrate con'),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 20,
                            runSpacing: 15,
                            alignment: WrapAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.facebook),
                                iconSize: 40,
                                color: Colors.blue,
                                onPressed: () {
                                  // Implementa el registro con Facebook
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.g_mobiledata),
                                iconSize: 40,
                                color: Colors.red,
                                onPressed: () {
                                  // Implementa el registro con Google
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('¿Ya tienes cuenta? '),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                ),
                                child: Text(
                                  'Inicia sesión',
                                  style: TextStyle(
                                    color: lightColorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DividerWithText extends StatelessWidget {
  final String text;
  const DividerWithText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            thickness: 0.7,
            color: Colors.grey,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        const Expanded(
          child: Divider(
            thickness: 0.7,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
