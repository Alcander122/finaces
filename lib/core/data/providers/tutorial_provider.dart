import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/providers/auth_provider.dart';

/// Proveedor que indica si el usuario ya vio el tutorial.
/// - `true` → ya lo vio
/// - `false` → primera vez
/// - Usa persistencia híbrida (SharedPreferences + Firestore)
final tutorialProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated || authState.user == null) {
    // Si el usuario no está logueado, por seguridad no mostramos el tutorial
    return true; 
  }

  final uid = authState.user!.uid;
  final prefs = await SharedPreferences.getInstance();
  
  // 🔑 Llave única por usuario para evitar multi-user overrides
  final localSeen = prefs.getBool('tutorial_seen_$uid') ?? false;

  if (localSeen) {
    debugPrint('>>> [tutorialProvider] Usuario $uid ya vio el tutorial localmente.');
    return true;
  }

  // ☁️ Comprobar persistencia cruzada en Firestore
  try {
    debugPrint('>>> [tutorialProvider] Buscando tutorialSeen en Firestore para: $uid');
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      final firestoreSeen = data?['tutorialSeen'] == true;
      if (firestoreSeen) {
        // Sincronizar localmente para futuros arranques rápidos sin red
        await prefs.setBool('tutorial_seen_$uid', true);
        debugPrint('>>> [tutorialProvider] Sincronizado tutorialSeen=true en SharedPreferences para: $uid');
        return true;
      }
    }
  } catch (e) {
    debugPrint('⚠️ Error leyendo tutorialSeen de Firestore: $e');
  }

  debugPrint('>>> [tutorialProvider] El usuario $uid NO ha completado el tutorial.');
  return false;
}, name: 'tutorialProvider');

/// Notificador para controlar el estado del tutorial
final tutorialNotifierProvider = Provider<OnboardingNotifier>((ref) {
  return OnboardingNotifier(ref);
});

/// Controlador del tutorial
class OnboardingNotifier {
  final Ref ref;

  OnboardingNotifier(this.ref);

  /// Marca el tutorial como visto en ambos repositorios
  Future<void> markAsSeen() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      debugPrint('⚠️ Intento de marcar tutorial como visto sin usuario autenticado.');
      return;
    }
    
    final uid = authState.user!.uid;
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Guardar en SharedPreferences localmente
    await prefs.setBool('tutorial_seen_$uid', true);
    debugPrint('>>> [markAsSeen] Tutorial marcado visto localmente para usuario: $uid');

    // 2. Guardar en Firestore para sincronización entre múltiples dispositivos
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'tutorialSeen': true,
      });
      debugPrint('>>> [markAsSeen] Tutorial marcado visto en Firestore para usuario: $uid');
    } catch (e) {
      debugPrint('⚠️ Error guardando tutorialSeen en Firestore: $e');
    }

    ref.invalidate(tutorialProvider); // Refresca el provider reactivamente
  }

  /// Reinicia el estado (útil para pruebas o depuración)
  Future<void> reset() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) return;
    
    final uid = authState.user!.uid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tutorial_seen_$uid');
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'tutorialSeen': FieldValue.delete(),
      });
      debugPrint('>>> [reset] Estado del tutorial reiniciado en local y Firestore.');
    } catch (_) {}

    ref.invalidate(tutorialProvider);
  }
}
