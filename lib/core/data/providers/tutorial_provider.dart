import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Proveedor que indica si el usuario ya vio el tutorial de bienvenida.
/// - Devuelve `true` si ya lo vio.
/// - Devuelve `false` si es la primera vez.
/// - Usa `ref.keepAlive()` para que NO se destruya al cerrar sesión.
final tutorialProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final hasSeen = prefs.getBool('has_seen_tutorial') ?? false;
  debugPrint(
      '>>> [tutorialProvider] Valor leído de SharedPreferences: $hasSeen');

  // ✅ ¡CLAVE! Mantener el provider vivo incluso si no hay listeners
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
    await prefs.setBool('has_seen_tutorial', true);
    final savedValue = prefs.getBool('has_seen_tutorial');
    debugPrint(
        '>>> [OnboardingNotifier.markAsSeen] Tutorial marcado como visto. Valor actual: $savedValue');

    // ✅ ¡CLAVE! Invalidamos el provider para que se vuelva a leer el nuevo valor
    ref.invalidate(tutorialProvider);
  }
}
