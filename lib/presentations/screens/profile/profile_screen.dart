// profile_screen.dart - MODIFICADO PARA SOLUCIONAR EL PROBLEMA DE REDIRECCIÓN
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/presentations/screens/auth/welcome_screen.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importamos los widgets separados
import 'widgets/profile_header.dart';
import 'widgets/profile_name_field.dart';
import 'widgets/profile_biometric_settings.dart';

/// Pantalla principal del perfil
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _prefillUserName();
  }

  void _prefillUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Themes.light,
      appBar: const AppBarFinances(
        title: 'Perfil',
        showProfileIcon: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                kToolbarHeight -
                MediaQuery.of(context).padding.top -
                32,
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ProfileHeader(user: authState.user),
                const SizedBox(height: 32),
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Formulario principal
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          ProfileNameField(controller: _nameController),
          const SizedBox(height: 24),
          const ProfileBiometricSettings(),
          const SizedBox(height: 24),
          _buildSaveButton(),
          const SizedBox(height: 16),
          _buildExitButton(),
          const SizedBox(height: 16),
          _buildDeleteAccountButton(),
        ],
      ),
    );
  }

  /// Botón guardar cambios
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _onSavePressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Themes.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              )
            : const Text(
                'Guardar Cambios',
                style: TextStyle(fontSize: 16, color: Themes.white),
              ),
      ),
    );
  }

  Future<void> _onSavePressed() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(authProvider.notifier)
          .updateDisplayName(_nameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado exitosamente')),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Botón salir
  Widget _buildExitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.exit_to_app, color: Themes.white),
        label: const Text(
          'Salir',
          style: TextStyle(color: Themes.white),
        ),
        onPressed: _onExitPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _onExitPressed() async {
    await Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.appBlocked,
      (Route<dynamic> route) => false,
    );
  }

  /// Botón para eliminar cuenta - CORREGIDO
  Widget _buildDeleteAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.delete_forever, color: Colors.white),
        label: _isDeleting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white),
              )
            : const Text('Eliminar Cuenta',
                style: TextStyle(color: Colors.white)),
        onPressed: _isDeleting ? null : _onDeleteAccountPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  /// Maneja el proceso de eliminación de cuenta - SOLUCIÓN DEFINITIVA
  Future<void> _onDeleteAccountPressed() async {
    // 1. Confirmación inicial
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar cuenta',
                style: TextStyle(color: Colors.red)),
            content: const Text(
              '¿Estás seguro? Se eliminarán todos tus datos y no podrás recuperar la cuenta.',
              style: TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    // 2. Solicitar contraseña para reautenticación
    final password = await _showPasswordDialog();
    if (password == null) return;

    setState(() => _isDeleting = true);

    try {
      // 3. Intentar eliminar la cuenta
      await ref.read(authProvider.notifier).deleteAccount(password);

      // 4. ¡CRÍTICO! Verificar explícitamente que el estado es unauthenticated
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        debugPrint('Usuario no autenticado - listo para redirigir');

        // 4.1 Eliminar TODAS las pantallas del stack (importante para evitar "atascos")
        Navigator.of(context).popUntil((route) => route.isFirst);

        // 4.2 Redirigir al WelcomeScreen usando pushReplacement
        // ¡ESTO ES LO MÁS IMPORTANTE! No uses pushNamedAndRemoveUntil aquí
        // porque depende del estado de autenticación para decidir qué mostrar
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );

        return; // Salir del método aquí
      }

      // Si llegamos aquí, el estado no se actualizó inmediatamente
      debugPrint('Estado aún autenticado - esperando actualización');

      // 5. Esperar a que el estado se actualice (máximo 1 segundo)
      int attempts = 0;
      const maxAttempts = 10;

      while (attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 100));
        final updatedAuthState = ref.read(authProvider);

        if (!updatedAuthState.isAuthenticated) {
          debugPrint('Estado actualizado - listo para redirigir');

          // Eliminar TODAS las pantallas del stack
          Navigator.of(context).popUntil((route) => route.isFirst);

          // Redirigir al WelcomeScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          );

          return; // Salir del método aquí
        }

        attempts++;
        debugPrint('Intento $attempts/$maxAttempts para actualizar estado...');
      }

      // 6. Si llegamos aquí, forzamos la redirección (último recurso)
      debugPrint('Forzando redirección al WelcomeScreen');

      // Eliminar TODAS las pantallas del stack
      Navigator.of(context).popUntil((route) => route.isFirst);

      // Redirigir al WelcomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    } catch (e) {
      String errorMessage;

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'requires-recent-login':
            errorMessage =
                'Debes iniciar sesión recientemente para eliminar tu cuenta.';
            break;
          case 'wrong-password':
            errorMessage =
                'Contraseña incorrecta. Por favor, verifica tu contraseña e intenta nuevamente.';
            break;
          default:
            errorMessage =
                'Error al eliminar la cuenta: ${e.message ?? 'desconocido'}';
        }
      } else {
        errorMessage =
            'Error al eliminar la cuenta. Por favor, intenta nuevamente.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  /// Muestra un diálogo para ingresar la contraseña
  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Por seguridad, ingresa tu contraseña:'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Contraseña',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result;
  }
}
