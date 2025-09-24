// register.screen.dart (MODIFICADO Y COMENTADO)
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/auth_error_handler.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:flutter/material.dart';
import 'LoginScreen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:finances/presentations/widgets/custom_scaffold.dart';
import 'package:finances/presentations/screens/terms_acceptance.screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Controladores de campos
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Estados
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  final _formSignupKey = GlobalKey<FormState>();
  bool agreePersonalData = false;

  /// Mostrar mensajes tipo SnackBar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  /// Lógica de registro
  void register(BuildContext context) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      if (_formSignupKey.currentState!.validate() && agreePersonalData) {
        final authNotifier = ref.read(authProvider.notifier);

        // 🔹 Llamada al signUp del provider
        await authNotifier.signUp(
          _nameController.text.trim(),
          _usernameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // 🔹 Cerrar sesión inmediatamente después de registro
        await FirebaseAuth.instance.signOut();

        // 🔹 Mostrar mensaje de éxito
        _showSnackBar(ErrorStrings.registrationSuccess, Colors.green);

        // 🔹 Redirigir al LoginScreen
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } else if (!agreePersonalData) {
        _showSnackBar(ErrorStrings.termsNotAccepted, Colors.red);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = AuthErrorHandler.handle(e);
      _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      _showSnackBar('Ocurrió un error inesperado.', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ❌ Eliminamos el listener de authProvider → ya no vamos directo al Home
    return CustomScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.fromLTRB(25, 50, 25, 20),
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
                            /// 🔹 Título
                            Text(
                              'Registrarse',
                              style: TextStyle(
                                fontSize: 30.0,
                                fontWeight: FontWeight.w900,
                                color: Themes.degradientLight,
                              ),
                            ),
                            const SizedBox(height: 40.0),

                            /// Campos del formulario
                            _buildTextFields(),

                            /// 🔹 Checkbox aceptar términos
                            _buildTermsCheckbox(),

                            /// 🔹 Botón de registro
                            _buildRegisterButton(),

                            /// 🔹 Línea separadora
                            _buildDivider(),

                            /// 🔹 Login con Google
                            _buildGoogleLogin(),

                            /// 🔹 Link a pantalla Login
                            _buildLoginLink(),
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

  // ------------------- Widgets reutilizables -------------------

  Widget _buildTextFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          validator: (value) =>
              value?.isEmpty ?? true ? ErrorStrings.requiredField : null,
          decoration: _inputDecoration('Nombre Completo'),
        ),
        const SizedBox(height: 25.0),
        TextFormField(
          controller: _usernameController,
          validator: (value) =>
              value?.isEmpty ?? true ? ErrorStrings.requiredField : null,
          decoration: _inputDecoration('Nombre Usuario'),
        ),
        const SizedBox(height: 25.0),
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
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          validator: (value) =>
              value?.isEmpty ?? true ? ErrorStrings.requiredField : null,
          decoration: _inputDecoration('Contraseña').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
        ),
        const SizedBox(height: 25.0),
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
          decoration: _inputDecoration('Confirmar Contraseña').copyWith(
            suffixIcon: IconButton(
              icon: Icon(_isConfirmPasswordVisible
                  ? Icons.visibility
                  : Icons.visibility_off),
              onPressed: () => setState(
                  () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
            ),
          ),
        ),
        const SizedBox(height: 25.0),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: agreePersonalData,
          onChanged: (value) =>
              setState(() => agreePersonalData = value ?? false),
          activeColor: Themes.degradientLight,
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              children: [
                const TextSpan(text: 'Al registrarte, aceptas nuestros '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => _showTermsDialog(context),
                    child: Text(
                      'Términos y Condiciones',
                      style: TextStyle(
                        color: Themes.degradientLight,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ' y '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => _showPrivacyPolicyDialog(context),
                    child: Text(
                      'Política de Privacidad',
                      style: TextStyle(
                        color: Themes.degradientLight,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => register(context),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Registrar'),
      ),
    );
  }

  Widget _buildDivider() {
    return Column(
      children: [
        const SizedBox(height: 30.0),
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
      ],
    );
  }

  Widget _buildGoogleLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () async {
            try {
              final authNotifier = ref.read(authProvider.notifier);
              final isNewUser = await authNotifier.signInWithGoogle();
              if (isNewUser) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TermsAcceptanceScreen()),
                );
              } else {
                _showSnackBar(
                    "Su cuenta ya se encuentra registrada.", Colors.blue);
              }
            } catch (e) {
              _showSnackBar(e.toString(), Colors.red);
            }
          },
          child: Logo(Logos.google),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿Ya tienes una cuenta? ',
            style: TextStyle(color: Colors.black45)),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
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
    );
  }

  // ------------------- Utilidades -------------------

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ErrorStrings.termsAndConditionsTitle),
        content: SingleChildScrollView(
          child: Text(ErrorStrings.termsAndConditionsContent,
              style: Theme.of(context).textTheme.bodyMedium),
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

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ErrorStrings.privacyPolicyTitle),
        content: SingleChildScrollView(
          child: Text(ErrorStrings.privacyPolicyContent,
              style: Theme.of(context).textTheme.bodyMedium),
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

  bool _validateEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }
}
