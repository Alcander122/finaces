import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/auth_error_handler.dart';
import 'package:finances/presentations/screens/auth/register.screen.dart';
import 'package:finances/presentations/screens/home/home_screen.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/widgets/custom_scaffold.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:finances/utils/ui_helpers.dart';
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

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }


  String _handleError(Object error) {
    if (error is FirebaseAuthException) {
      return AuthErrorHandler.handle(error);
    }
    return ErrorStrings.unexpectedError;
  }

  void _showErrorFeedback(String message) {
    if (!mounted) return;
    UIHelpers.showErrorSnackBar(context: context, message: message);
  }

  Future<void> _performLogin() async {
    if (!_validateFields()) return;

    try {
      await ref.read(authProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

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
      // AppBar sin flechas.
      appBar: AppBar(
        automaticallyImplyLeading: false, // Desactiva la flecha de la izquierda
        backgroundColor: Colors.white,
        elevation: 0,
        // Eliminamos el IconButton de 'actions' para quitar la flecha de la derecha
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
                            color: lightColorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 40.0),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Logo(Logos.facebook_f),
                            Consumer(
                            builder: (context, ref, _) {
                              return GestureDetector(
                                onTap: () async {
                                  try {
                                    final authNotifier =
                                        ref.read(authProvider.notifier);
                                    await authNotifier.signInWithGoogle();
                                    if (mounted) {
                                      Navigator.pushAndRemoveUntil(
                                        // ignore: use_build_context_synchronously
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const HomeScreen()),
                                        (route) => false,
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

  Widget _buildDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Divider(
            thickness: 0.7,
            color: Colors.grey.withOpacity(0.5),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('Login', style: TextStyle(color: Colors.black45)),
        ),
        Expanded(
          child: Divider(
            thickness: 0.7,
            color: Colors.grey.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('No tienes cuenta? ',
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
              color: lightColorScheme.primary,
            ),
          ),
        ),
      ],
    );
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
}
