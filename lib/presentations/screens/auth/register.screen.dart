import 'package:finances/core/data/services/user_service.dart';
import 'package:flutter/material.dart';
import 'LoginScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/widgets/custom_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formSignupKey = GlobalKey<FormState>();
  bool agreePersonalData = true;

  bool _validateEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  void register(BuildContext context) async {
    if (!_validateEmail(_emailController.text)) {
      _showSnackBar('Correo electrónico no válido', Colors.red);
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Las contraseñas no coinciden', Colors.red);
      return;
    }

    try {
      final userService = UserService();
      await userService.registerUser(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );

      _showSnackBar(
          'Registro exitoso. Por favor, inicia sesión.', Colors.green);
    } catch (e) {
      String errorMessage = 'Error al registrar usuario';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'El correo electrónico ya está en uso';
            break;
          case 'invalid-email':
            errorMessage = 'El correo electrónico no es válido';
            break;
          case 'weak-password':
            errorMessage = 'La contraseña es demasiado débil';
            break;
          default:
            errorMessage = 'Error inesperado. Intenta de nuevo.';
        }
      }
      _showSnackBar(errorMessage, Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Registrarse',
                          style: TextStyle(
                            fontSize: 30.0,
                            fontWeight: FontWeight.w900,
                            color: lightColorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        _buildTextField(
                            _nameController, 'Nombre', 'Ingresa tu nombre'),
                        const SizedBox(height: 20),
                        _buildTextField(_usernameController, 'Usuario',
                            'Ingresa tu usuario'),
                        const SizedBox(height: 20),
                        _buildEmailField(),
                        const SizedBox(height: 20),
                        _buildPasswordField(_passwordController, 'Contraseña'),
                        const SizedBox(height: 20),
                        _buildPasswordField(
                            _confirmPasswordController, 'Confirmar contraseña'),
                        _buildTermsCheckbox(),
                        const SizedBox(height: 25),
                        ElevatedButton(
                          onPressed: () => _handleRegistration(context),
                          child: const Text('Registrar'),
                        ),
                        const SizedBox(height: 30),
                        _buildSocialSection(),
                        const SizedBox(height: 20),
                        _buildLoginLink(),
                      ],
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

  Widget _buildTextField(
      TextEditingController controller, String label, String hint) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
      ),
      validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Correo electrónico',
        hintText: 'tucorreo@ejemplo.com',
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
      ),
      validator: (value) {
        if (value!.isEmpty) return 'Ingresa tu correo';
        if (!_validateEmail(value)) return 'Formato de correo inválido';
        return null;
      },
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
      ),
      validator: (value) {
        if (value!.isEmpty) return 'Este campo es obligatorio';
        if (value.length < 6) return 'Mínimo 6 caracteres';
        return null;
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: agreePersonalData,
          onChanged: (value) => setState(() => agreePersonalData = value!),
          activeColor: lightColorScheme.primary,
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: 'Acepto el procesamiento de ',
              style: const TextStyle(color: Colors.black45),
              children: [
                TextSpan(
                  text: 'Datos personales',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: lightColorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        const DividerWithText(text: 'O inicia con'),
        const SizedBox(height: 20),
        Wrap(
          spacing: 20,
          runSpacing: 15,
          alignment: WrapAlignment.center,
          children: [
            Logo(Logos.facebook_f, size: 30),
            /*Logo(Logos.twitter, size: 30),*/
            Logo(Logos.google, size: 30),
            /*Logo(Logos.apple, size: 30),*/
          ],
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      ),
      child: RichText(
        text: TextSpan(
          text: '¿Ya tienes cuenta? ',
          style: const TextStyle(color: Colors.black45),
          children: [
            TextSpan(
              text: 'Inicia sesión',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: lightColorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _inputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.black12),
    );
  }

  void _handleRegistration(BuildContext context) {
    if (_formSignupKey.currentState!.validate()) {
      if (agreePersonalData) {
        register(context);
      } else {
        _showSnackBar(
            'Debes aceptar los términos para continuar', Colors.orange);
      }
    }
  }
}

class DividerWithText extends StatelessWidget {
  final String text;
  const DividerWithText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 0.7)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(text, style: const TextStyle(color: Colors.black45)),
        ),
        const Expanded(child: Divider(thickness: 0.7)),
      ],
    );
  }
}
