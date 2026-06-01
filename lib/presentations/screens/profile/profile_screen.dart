import 'dart:ui';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/premium_provider.dart'; // 🆕 Para gestión de anuncios
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/screens/auth/welcome_screen.dart';
import 'package:finances/presentations/screens/Tutorial/TutorialScreen.dart';
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
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0E14).withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. Aurora Radial Superior Derecha (Azul profundo neón)
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF003366).withValues(alpha: 0.25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006699).withValues(alpha: 0.2),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          // 2. Aurora Radial Inferior Izquierda (Púrpura suave)
          Positioned(
            bottom: -200,
            left: -200,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF5D3FD3).withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8A2BE2).withValues(alpha: 0.08),
                    blurRadius: 180,
                    spreadRadius: 70,
                  ),
                ],
              ),
            ),
          ),
          // 3. Contenido Principal Scrollable
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // Encabezado con imagen y correo
                  ProfileHeader(user: authState.user),
                  const SizedBox(height: 20),

                  // Formulario y Ajustes
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Card 1: Datos Personales
                        _GlassmorphicCard(
                          borderRadius: 20.0,
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DATOS PERSONALES',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ProfileNameField(controller: _nameController),
                              const SizedBox(height: 16),
                              _buildSaveButton(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Card 2: Seguridad y Biometría
                        _GlassmorphicCard(
                          borderRadius: 20.0,
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Text(
                                  'SEGURIDAD',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              ProfileBiometricSettings(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Card 3: Sección Monetización (Premium)
                        _GlassmorphicCard(
                          borderRadius: 20.0,
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MEMBRESÍA & MONETIZACIÓN',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (!isPremium)
                                _buildPremiumButton()
                              else
                                _buildPremiumBadge(),
                              const SizedBox(height: 8),
                              Center(child: _buildRestoreButton()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Card 4: Acciones de Cuenta
                        _GlassmorphicCard(
                          borderRadius: 20.0,
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ACCIONES DE CUENTA',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildExitButton(),
                              const SizedBox(height: 12),
                              Center(child: _buildTutorialButton()),
                              const Divider(color: Colors.white10, height: 32),
                              _buildDeleteAccountButton(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB74D), Color(0xFFFFA726)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB74D).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          label: const Text(
            'Quitar Publicidad (Premium)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          onPressed: () => ref.read(premiumProvider.notifier).buyPremium(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  /// Badge que se muestra cuando el usuario ya es premium
  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB74D).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.stars_rounded, color: Color(0xFFFFB74D), size: 22),
          SizedBox(width: 10),
          Text(
            'USUARIO PREMIUM ACTIVO',
            style: TextStyle(color: Color(0xFFFFB74D), fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  /// Botón para restaurar compras previas (Requisito legal de tiendas)
  Widget _buildRestoreButton() {
    return TextButton(
      onPressed: () => ref.read(premiumProvider.notifier).restorePurchases(),
      child: const Text(
        'Restaurar compras anteriores',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 13,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white30,
        ),
      ),
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
          backgroundColor: const Color(0xFF26A69A), // Esmeralda
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Guardar Cambios',
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
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
        UIHelpers.showSuccessSnackBar(
            context: context, message: 'Perfil actualizado correctamente');
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(
            context: context, message: 'Error al actualizar');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Botón: Salir / Bloquear Sesión
  Widget _buildExitButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF5350), size: 18),
        label: const Text(
          'Cerrar Sesión / Bloquear',
          style: TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold, fontSize: 14),
        ),
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.appBlocked, (_) => false),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  /// Botón: Ver tutorial de nuevo
  Widget _buildTutorialButton() {
    return TextButton.icon(
      icon: const Icon(Icons.help_outline_rounded, size: 18, color: Colors.white60),
      label: const Text('Ver tutorial de la aplicación', style: TextStyle(color: Colors.white60, fontSize: 13)),
      onPressed: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const TutorialScreen())),
    );
  }

  /// Botón: Eliminar cuenta (Acción Crítica)
  Widget _buildDeleteAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isDeleting ? null : _onDeleteAccountPressed,
        icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 18),
        label: const Text(
          'Eliminar mi cuenta definitivamente',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF5350).withValues(alpha: 0.15),
          foregroundColor: const Color(0xFFEF5350),
          side: const BorderSide(color: Color(0xFFEF5350), width: 1.0),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
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

// --- CONTENEDOR GLASSMORPHIC AUXILIAR ---
class _GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double borderOpacity;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  const _GlassmorphicCard({
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 20.0,
    this.borderOpacity = 0.1,
    this.backgroundColor = const Color(0x0DFFFFFF),
    this.padding = const EdgeInsets.all(20.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: borderOpacity),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
