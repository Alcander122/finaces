import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/services/BiometricAuthService.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/auth_error_handler.dart';
import 'package:finances/presentations/screens/Auth/register.screen.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/widgets/custom_scaffold.dart';
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
  bool _biometricEnabled =
      false; // 👈 para controlar si mostrar el botón de huella

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  /// 🔹 Revisa si la biometría está activada en el dispositivo
  Future<void> _checkBiometricStatus() async {
    final enabled = await BiometricAuthService().isBiometricEnabled();
    if (mounted) {
      setState(() => _biometricEnabled = enabled);
    }
  }

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

  /// 🔹 Login con email y contraseña
  /// 🔹 Login con email y contraseña
  Future<void> _performLogin() async {
    if (!_validateFields() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

      if (mounted) {
        // ✅ Mostrar mensaje de éxito
        UIHelpers.showSuccessSnackBarNew(
          context: context,
          message: 'Inicio de sesión exitoso',
        );

        // 🔹 Navegar al Home inmediatamente
        Navigator.pushReplacementNamed(context, '/home');
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

  /// 🔹 Login con huella
  /// 🔹 Login con huella
  Future<void> _performBiometricLogin() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // ✅ Ahora pasamos el context al servicio
      final success = await BiometricAuthService().authenticate(context);

      if (success) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _showErrorFeedback("Autenticación cancelada o fallida");
      }
    } catch (e) {
      debugPrint("Error en login biométrico: $e");
      _showErrorFeedback("Error con la autenticación biométrica");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

                      // Loader cuando está autenticando
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
                            // Campo correo
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

                            // Campo contraseña
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              obscuringCharacter: '•',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return ErrorStrings.requiredField;
                                }
                                if (value.length < 6) {
                                  return "Mínimo 6 caracteres";
                                }
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

                            const SizedBox(height: 15.0),

                            // 👇 Botón de huella (solo si está activada)
                            if (_biometricEnabled)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Themes.primary,
                                  ),
                                  onPressed: _performBiometricLogin,
                                  icon: const Icon(Icons.fingerprint,
                                      color: Colors.white),
                                  label: const Text(
                                    "Ingresar con huella",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),

                      const SizedBox(height: 25.0),
                      _buildDivider(),
                      const SizedBox(height: 25.0),

                      // Botón login Google
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

  /// Divider entre login tradicional y social login
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

  /// Sección para ir a registro
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

  /// Estilo inputs
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
