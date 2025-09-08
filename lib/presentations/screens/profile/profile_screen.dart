// profile_screen.dart
import 'package:finances/core/data/services/BiometricAuthService.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:finances/presentations/theme/themes.dart';

/// Pantalla de edición de perfil con biometría y opciones de sesión
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Precargar el nombre del usuario autenticado
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
        title: 'Editar Perfil',
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
                // Tarjeta superior con avatar, nombre y correo
                _buildProfileInfo(authState.user),
                const SizedBox(height: 32),

                // Formulario principal
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildNameField(),
                      const SizedBox(height: 24),
                      _buildBiometricSettings(),
                      const SizedBox(height: 24),
                      _buildSaveButton(),
                      const SizedBox(height: 16),
                      _buildLogoutButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Tarjeta superior con info del usuario
  Widget _buildProfileInfo(User? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Themes.degradientDark, Themes.degradientLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: Themes.iconsButton,
            child: Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, ${user?.displayName ?? 'Sin nombre'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user?.email ?? 'Sin email',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Campo de nombre
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Nombre',
        prefixIcon: const Icon(Icons.person, color: Themes.iconColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor, ingresa un nombre';
        }
        final trimmed = value.trim();
        if (trimmed.length < 3) {
          return 'El nombre debe tener al menos 3 caracteres';
        }
        if (trimmed.length > 30) {
          return 'El nombre no debe exceder los 30 caracteres';
        }
        final validNameRegExp = RegExp(r'^[a-zA-Z0-9\s]+$');
        if (!validNameRegExp.hasMatch(trimmed)) {
          return 'Solo se permiten letras, números y espacios';
        }
        return null;
      },
    );
  }

  /// 🔹 Switch de configuración biométrica
  Widget _buildBiometricSettings() {
    return FutureBuilder<bool>(
      future: BiometricAuthService().isBiometricAvailable(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            title: Text('Autenticación Biométrica'),
            subtitle: Text('Verificando disponibilidad...'),
            trailing: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        if (snapshot.hasError || !snapshot.data!) {
          return const ListTile(
            title: Text('Autenticación Biométrica'),
            subtitle: Text('No disponible en este dispositivo'),
            trailing: Icon(Icons.block, color: Colors.grey),
          );
        }
        return FutureBuilder<bool>(
          future: BiometricAuthService().isBiometricEnabled(),
          builder: (context, enabledSnapshot) {
            if (enabledSnapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(
                title: Text('Autenticación Biométrica'),
                trailing: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            return SwitchListTile(
              title: const Text('Iniciar sesión con huella'),
              subtitle: const Text('Protege tu app con tu biometría'),
              value: enabledSnapshot.data ?? false,
              onChanged: (bool value) async {
                try {
                  await BiometricAuthService().setBiometricEnabled(value);
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? '✅ Autenticación biométrica activada'
                              : '❌ Autenticación biométrica desactivada',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚠️ Error al cambiar la configuración'),
                      ),
                    );
                  }
                }
              },
              activeThumbColor: Themes.primary,
              secondary: const Icon(Icons.fingerprint),
            );
          },
        );
      },
    );
  }

  /// 🔹 Botón guardar cambios
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving
            ? null
            : () async {
                if (_formKey.currentState?.validate() ?? false) {
                  setState(() => _isSaving = true);
                  try {
                    await ref
                        .read(authProvider.notifier)
                        .updateDisplayName(_nameController.text.trim());
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Perfil actualizado exitosamente'),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                }
              },
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

  /// 🔹 Botón cerrar sesión
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout, color: Themes.white),
        label: const Text(
          'Cerrar sesión',
          style: TextStyle(color: Themes.white),
        ),
        onPressed: () => _showLogoutDialog(context),
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

  /// 🔹 Diálogo de opciones de salida
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Qué deseas hacer?'),
        content: const Text(
          'Puedes bloquear la app (pedirá huella al reabrir) o cerrar sesión completamente (requerirá login de nuevo).',
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.4),
        ),
        actions: [
          // Cancelar
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),

          // 🔒 Bloquear app → Mantiene login, pero exige huella al volver
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (!mounted) return;

              await Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.appBlocked,
                (Route<dynamic> route) => false,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('🔒 App bloqueada. Usa tu huella para volver.'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('Bloquear app'),
              ],
            ),
          ),

          // 🚪 Cerrar sesión → Limpia biometría y sesión
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (!mounted) return;

              try {
                // 1️⃣ Limpia la configuración biométrica
                await BiometricAuthService().clearBiometricSetting();

                // 2️⃣ Cierra sesión Firebase
                await ref.read(authProvider.notifier).signOut();

                // 3️⃣ Manda al WelcomeScreen
                await Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.welcome,
                  (Route<dynamic> route) => false,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('👋 Sesión cerrada correctamente.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error al cerrar sesión: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          '⚠️ Error al cerrar sesión. Inténtalo de nuevo.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text('Cerrar sesión'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
