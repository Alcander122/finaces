import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/premium_provider.dart'; // 🆕 Para gestión de anuncios
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
import 'package:finances/core/data/services/user_service.dart';

// Widgets internos del perfil
import 'widgets/profile_header.dart';
import 'widgets/profile_name_field.dart';
import 'widgets/profile_biometric_settings.dart';
import 'widgets/delete_account_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  // Estados locales para animaciones de carga
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _prefillUserName();
  }

  /// Carga el nombre actual del usuario al iniciar la pantalla
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
    // Escuchamos los cambios de autenticación y de estado Premium
    final authState = ref.watch(authProvider);
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      backgroundColor: Themes.light,
      appBar: const AppBarFinances(title: 'Perfil', showProfileIcon: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Encabezado con imagen y correo
            ProfileHeader(user: authState.user),
            const SizedBox(height: 32),

            // 2. Formulario y Ajustes
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Campo para editar nombre
                  ProfileNameField(controller: _nameController),
                  const SizedBox(height: 24),

                  // Ajustes de huella / biometría
                  const ProfileBiometricSettings(),
                  const SizedBox(height: 24),

                  // --- SECCIÓN MONETIZACIÓN (PREMIUM) ---
                  if (!isPremium)
                    _buildPremiumButton()
                  else
                    _buildPremiumBadge(),

                  const SizedBox(height: 12),
                  _buildRestoreButton(), // Obligatorio para tiendas de apps

                  const Divider(height: 40),

                  // --- ACCIONES DE CUENTA ---
                  _buildSaveButton(),
                  const SizedBox(height: 16),
                  _buildExitButton(),
                  const SizedBox(height: 16),
                  _buildTutorialButton(),
                  const SizedBox(height: 40),
                  _buildDeleteAccountButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // SECCIÓN DE MONETIZACIÓN
  // ============================================================================

  /// Botón para comprar la versión sin anuncios
  Widget _buildPremiumButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text('Quitar Publicidad (Premium)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => ref.read(premiumProvider.notifier).buyPremium(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade800,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// Badge que se muestra cuando el usuario ya es premium
  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade700),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stars, color: Colors.amber.shade800),
          const SizedBox(width: 10),
          Text('USUARIO PREMIUM ACTIVO',
              style: TextStyle(
                  color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Botón para restaurar compras previas (Requisito legal de tiendas)
  Widget _buildRestoreButton() {
    return TextButton(
      onPressed: () => ref.read(premiumProvider.notifier).restorePurchases(),
      child: const Text('Restaurar compras anteriores',
          style: TextStyle(
              color: Colors.grey, decoration: TextDecoration.underline)),
    );
  }

  // ============================================================================
  // BOTONES DE ACCIÓN
  // ============================================================================

  /// Botón: Guardar cambios de nombre
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
            context: context, message: 'Perfil actualizado correctamente');
      }
    } catch (e) {
      if (mounted)
        UIHelpers.showErrorSnackBar(
            context: context, message: 'Error al actualizar');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Botón: Salir / Bloquear Sesión
  Widget _buildExitButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.appBlocked, (_) => false),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// Botón: Ver tutorial de nuevo
  Widget _buildTutorialButton() {
    return TextButton.icon(
      icon: const Icon(Icons.help_outline, size: 20),
      label: const Text('Ver tutorial de la app'),
      onPressed: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const TutorialScreen())),
    );
  }

  /// Botón: Eliminar cuenta (Acción Crítica)
  Widget _buildDeleteAccountButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton.icon(
        onPressed: _isDeleting ? null : _onDeleteAccountPressed,
        icon: const Icon(Icons.delete_forever),
        label: const Text('Eliminar mi cuenta definitivamente'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // LÓGICA DE ELIMINACIÓN DE CUENTA
  // ============================================================================

  Future<void> _onDeleteAccountPressed() async {
    setState(() => _isDeleting = true);

    final authProviderType = UserService().getAuthProviderType();

    final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => DeleteAccountDialog(
            authProvider: authProviderType,
            onDelete: (password) async {
              await ref
                  .read(authProvider.notifier)
                  .deleteAccount(password: password);
            },
          ),
        ) ??
        false;

    if (!confirmed) {
      if (mounted) setState(() => _isDeleting = false);
      return;
    }

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }
}
