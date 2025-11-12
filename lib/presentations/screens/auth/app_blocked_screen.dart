// lib/presentations/screens/app_blocked_screen.dart
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/services/BiometricAuthService.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:finances/presentations/theme/themes.dart';

class AppBlockedScreen extends ConsumerStatefulWidget {
  const AppBlockedScreen({super.key});

  @override
  ConsumerState<AppBlockedScreen> createState() => _AppBlockedScreenState();
}

class _AppBlockedScreenState extends ConsumerState<AppBlockedScreen> {
  bool _isAuthenticating = false;

  /// Intenta autenticar con biometría y maneja el resultado según el estado.
  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    final service = BiometricAuthService();
    final status = await service.authenticateWithStatus();
    setState(() => _isAuthenticating = false);

    if (!mounted) return;

    switch (status) {
      case BiometricAuthStatus.success:
        // ✅ Huella correcta → ir al Home
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (r) => false,
        );
        break;

      case BiometricAuthStatus.canceled:
      case BiometricAuthStatus.failed:
        // ❗ Solo mostramos mensaje, sin redirección
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autenticación cancelada o fallida'),
            backgroundColor: Colors.red,
          ),
        );
        break;

      case BiometricAuthStatus.notAvailable:
        // ✅ MEJORA DE UX: Solo mostramos un SnackBar informativo
        // ❌ NO mostramos AlertDialog ni redirigimos al login
        // → El usuario decide si quiere usar "Ingresar con contraseña"
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No has activado la autenticación biométrica.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        break;

      case BiometricAuthStatus.error:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error en la autenticación. Intenta de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Themes.light,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 100, color: Themes.primary),
              const SizedBox(height: 20),
              const Text(
                "Tu sesión está protegida",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Confirma tu identidad con huella digital o inicia con tu contraseña.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Themes.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isAuthenticating ? null : _authenticate,
                icon: const Icon(Icons.fingerprint, color: Colors.white),
                label: _isAuthenticating
                    ? const SizedBox(
                        height: 16,
                        width: 120,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : const Text(
                        "Usar huella digital",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
              const SizedBox(height: 15),
              // 🔑 BOTÓN CORREGIDO: Ya NO llama a signOut()
              TextButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).signOut();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (r) => false,
                  );
                },
                child: const Text("Ingresar con contraseña"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
