// core/data/providers/tutorial_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Proveedor que indica si el usuario ya vio el tutorial.
/// - `true` → ya lo vio
/// - `false` → primera vez
/// - Usa keepAlive() para persistir
final tutorialProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final hasSeen = prefs.getBool('tutorial_seen') ?? false;

  debugPrint('>>> [tutorialProvider] ¿Ya vio el tutorial? $hasSeen');
  ref.keepAlive(); // Mantiene el provider vivo

  return hasSeen;
}, name: 'tutorialProvider');

/// Notificador para controlar el estado del tutorial
final tutorialNotifierProvider = Provider<OnboardingNotifier>((ref) {
  return OnboardingNotifier(ref);
});

/// Controlador del tutorial
class OnboardingNotifier {
  final Ref ref;

  OnboardingNotifier(this.ref);

  /// Marca el tutorial como visto (solo si no lo estaba)
  Future<void> markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadySeen = prefs.getBool('tutorial_seen') ?? false;

    if (alreadySeen) {
      debugPrint(
          '>>> [markAsSeen] Ya estaba marcado como visto. No se hace nada.');
      return;
    }

    await prefs.setBool('tutorial_seen', true);
    debugPrint('>>> [markAsSeen] Tutorial marcado como visto');
    ref.invalidate(tutorialProvider); // Refresca el provider
  }

  /// [OPCIONAL] Reinicia el estado (útil para pruebas o botón "ver de nuevo")
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tutorial_seen');
    debugPrint('>>> [reset] Estado del tutorial reiniciado');
    ref.invalidate(tutorialProvider);
  }

  /// Verifica si se debe mostrar el tutorial (para navegación automática)
  bool shouldShow() {
    // Este método NO lee SharedPreferences directamente
    // Usa el estado del provider
    return !ref.read(tutorialProvider).valueOrNull!;
  }
}
