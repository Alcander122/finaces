import 'dart:async'; // Permite usar StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore DB
import 'package:firebase_auth/firebase_auth.dart'; // Usuario autenticado
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Estado global
import 'package:shared_preferences/shared_preferences.dart'; // Caché local

// Provider global que expone si el usuario es premium (true/false)
final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});

// Clase que maneja el estado premium
class PremiumNotifier extends StateNotifier<bool> {
  // Instancia de Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Instancia de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Clave para guardar en caché local
  static const String _premiumCacheKey = 'user_is_premium';

  // Suscripción para escuchar cambios en tiempo real
  StreamSubscription? _subscription;

  // Constructor inicial (estado inicial false)
  PremiumNotifier() : super(false) {
    _init(); // Ejecuta inicialización
  }

  // Inicializa estado
  Future<void> _init() async {
    // 1. Obtener SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // 2. Cargar estado premium desde caché local
    state = prefs.getBool(_premiumCacheKey) ?? false;

    // 3. Escuchar cambios en Firestore en tiempo real
    _listenRealtime();
  }

  // Escucha cambios en Firestore
  void _listenRealtime() {
    final user = _auth.currentUser;

    // Si no hay usuario logueado, salir
    if (user == null) return;

    // Cancelar suscripción anterior si existe
    _subscription?.cancel();

    // Escuchar cambios del documento del usuario
    _subscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) async {
      // Si no existe el documento, salir
      if (!doc.exists) return;

      // Leer campo isPremium
      final isPremium = doc.data()?['isPremium'] == true;

      // Si el valor cambió
      if (state != isPremium) {
        state = isPremium; // actualizar estado

        // Guardar en caché local
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_premiumCacheKey, isPremium);
      }
    });
  }

  // Método para actualizar estado premium manualmente (compra)
  Future<void> setPremiumStatus(bool isPremium) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Guardar en Firestore
    await _firestore.collection('users').doc(user.uid).set(
      {'isPremium': isPremium},
      SetOptions(merge: true), // no sobrescribe otros campos
    );

    // Actualizar estado local
    state = isPremium;

    // Guardar en caché
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumCacheKey, isPremium);
  }

  // Liberar recursos cuando el provider se destruye
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
