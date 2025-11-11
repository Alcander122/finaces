// profile_screen.dart
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/presentations/screens/auth/welcome_screen.dart';
import 'package:finances/presentations/screens/Tutorial/TutorialScreen.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    _nameController.text = user?.displayName ?? '';
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
      appBar: const AppBarFinances(title: 'Perfil', showProfileIcon: false),
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
          const SizedBox(height: 16),
          _buildTutorialButton(), // ← NUEVO: Ver tutorial de nuevo
        ],
      ),
    );
  }

  /// Botón: Guardar cambios
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _onSavePressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Themes.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2)
            : const Text('Guardar Cambios',
                style: TextStyle(fontSize: 16, color: Colors.white)),
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
        UIHelpers.showSuccessSnackBar(
          context: context,
          message: ErrorStrings.profileUpdateSuccess,
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBarFromAuth(context: context, error: e);
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(
            context: context, message: ErrorStrings.unexpectedError);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Botón: Salir
  Widget _buildExitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.exit_to_app, color: Colors.white),
        label: const Text('Salir', style: TextStyle(color: Colors.white)),
        onPressed: _onExitPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _onExitPressed() async {
    await Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.appBlocked, (_) => false);
  }

  /// Botón: Eliminar cuenta
  Widget _buildDeleteAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.delete_forever, color: Colors.white),
        label: _isDeleting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white))
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

  Future<void> _onDeleteAccountPressed() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Eliminar cuenta',
                style: TextStyle(color: Colors.red)),
            content: const Text(
                '¿Estás seguro? Se eliminarán todos tus datos y no podrás recuperar la cuenta.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final password = await _showPasswordDialog();
    if (password == null) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(authProvider.notifier).deleteAccount(password);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBarFromAuth(context: context, error: e);
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(
            context: context, message: ErrorStrings.unexpectedError);
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
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
                  border: OutlineInputBorder(), labelText: 'Contraseña'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Confirmar')),
        ],
      ),
    );
  }

  /// Botón: Ver tutorial de nuevo
  Widget _buildTutorialButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.school, color: Themes.primary),
        label: const Text('Ver tutorial de nuevo',
            style: TextStyle(color: Themes.primary)),
        onPressed: _onTutorialPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Themes.primary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// Abre el tutorial sin afectar el estado de `tutorial_seen`
  void _onTutorialPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TutorialScreen()),
    );
  }
}
