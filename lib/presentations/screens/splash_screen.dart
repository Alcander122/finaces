// splash_screen.dart
// lib/presentations/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finances/core/data/services/BiometricAuthService.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/core/data/providers/tutorial_provider.dart';

/// Pantalla inicial que decide hacia dónde navegar según el estado de sesión.
/// Flujo:
/// - Sin sesión → Welcome.
/// - Con sesión y biometría desactivada → Home.
/// - Con sesión y biometría activada:
///    ✅ Correcta → Home.
///    ❌ Cancelada/fallida → AppBlocked (no cerrar sesión todavía).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  /// Verifica autenticación y decide la ruta inicial
  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 800)); // pequeña pausa
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // 1️⃣ No hay usuario logueado → ir a Welcome
      _goTo(AppRoutes.welcome);
      return;
    }

    // 2️⃣ Usuario logueado → revisar tutorial
    final tutorialSeen = await ref.read(tutorialProvider.future);
    if (!tutorialSeen) {
      // ℹ️ Si no ha visto el tutorial → ir a Tutorial
      _goTo(AppRoutes.tutorial);
      return;
    }

    // 3️⃣ Usuario logueado y vio tutorial → revisar biometría
    final biometricEnabled = await BiometricAuthService().isBiometricEnabled();
    if (!biometricEnabled) {
      // ℹ️ Si biometría no está activada → ir al Home directamente
      _goTo(AppRoutes.home);
      return;
    }

    // 3️⃣ Si biometría está activada → pedir autenticación biométrica
    final success = await BiometricAuthService().authenticate(context);
    if (success) {
      // ✅ Huella correcta → ir al Home
      _goTo(AppRoutes.home);
    } else {
      // ❌ Cancelada o fallida → ir a pantalla bloqueada
      _goTo(AppRoutes.appBlocked);
    }
  }

  /// Función de navegación segura
  void _goTo(String route) {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (Route<dynamic> r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Themes.light,
      body: Center(
        child: CircularProgressIndicator(color: Themes.primary),
      ),
    );
  }
}
