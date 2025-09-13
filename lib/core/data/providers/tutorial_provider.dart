// tutorial_provider.dart (CORREGIDO Y COMENTADO)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Proveedor que indica si el usuario ya vio el tutorial de bienvenida.
/// - Devuelve `true` si ya lo vio.
/// - Devuelve `false` si es la primera vez.
/// - Usa `ref.keepAlive()` para que NO se destruya al cerrar sesión.
final tutorialProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  // CLAVE UNIFICADA: usamos 'tutorial_seen' igual que en AuthStorage
  final hasSeen = prefs.getBool('tutorial_seen') ?? false;
  debugPrint(
      '>>> [tutorialProvider] Valor leído de SharedPreferences: $hasSeen');

  // ✅ Mantener el provider vivo incluso si no hay listeners
  ref.keepAlive();

  return hasSeen;
}, name: 'tutorialProvider');

/// Proveedor de notificador para marcar el tutorial como visto.
final tutorialNotifierProvider = Provider<OnboardingNotifier>((ref) {
  return OnboardingNotifier(ref);
});

/// Clase que permite marcar el tutorial como visto.
class OnboardingNotifier {
  final Ref ref;

  OnboardingNotifier(this.ref);

  /// Guarda en SharedPreferences que el usuario ya vio el tutorial.
  Future<void> markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    // CLAVE UNIFICADA: usamos 'tutorial_seen' igual que en AuthStorage
    await prefs.setBool('tutorial_seen', true);
    final savedValue = prefs.getBool('tutorial_seen');
    debugPrint(
        '>>> [OnboardingNotifier.markAsSeen] Tutorial marcado como visto. Valor actual: $savedValue');

    // ✅ Invalidamos el provider para que se vuelva a leer el nuevo valor
    ref.invalidate(tutorialProvider);
  }
}
