// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';

class AuthStorage {
  static const String _tokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      //print("❌ Error al guardar el token: $e");
    }
  }

  Future<void> deleteToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      //print("❌ Error al eliminar el token: $e");
    }
  }

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      //print("❌ Error al obtener el token: $e");
      return null;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<User?> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final AuthStorage _storage = AuthStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore

  AuthNotifier() : super(null) {
    _initAuthListener();
  }

  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      try {
        if (user != null) {
          String? token = await user.getIdToken();
          if (token != null) {
            await _storage.saveToken(token);
          }
        } else {
          await _storage.deleteToken();
        }
        state = user;
        //print("🔄 Estado de autenticación actualizado: ${user?.email ?? 'Desconectado'}");
      } catch (e) {
        //print("❌ Error en authStateChanges: $e");
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      //("✅ Inicio de sesión exitoso para: $email");
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      //print("❌ Error inesperado al iniciar sesión: $e");
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    try {
      await _userService.registerUser(
          name: name, email: email, password: password);
      //print("✅ Registro exitoso para: $email");
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      //print("❌ Error inesperado al registrar usuario: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _storage.deleteToken();
      state = null;
      //print("✅ Sesión cerrada exitosamente");
    } catch (e) {
      //print("❌ Error al cerrar sesión: $e");
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String errorMessage;
    switch (e.code) {
      case 'user-not-found':
        errorMessage = "Usuario no encontrado";
        break;
      case 'wrong-password':
        errorMessage = "Contraseña incorrecta";
        break;
      case 'email-already-in-use':
        errorMessage = "El correo ya está registrado";
        break;
      case 'weak-password':
        errorMessage = "La contraseña es muy débil";
        break;
      case 'invalid-email':
        errorMessage = "El correo electrónico no es válido";
        break;
      default:
        errorMessage = "Error de autenticación: ${e.message}";
    }
    //print("❌ $errorMessage");
    throw errorMessage;
  }

  // Método para actualizar el nombre del usuario en Firebase Auth y Firestore
  Future<void> updateDisplayName(String displayName) async {
    if (state != null) {
      // Actualizar el displayName en Firebase Authentication
      await state!.updateDisplayName(displayName);
      await state!.reload(); // Recargar el usuario para sincronizar
      state = FirebaseAuth.instance.currentUser; // Actualizar el estado

      // Actualizar en Firestore
      await updateUserInFirestore(state!.uid, displayName);
    }
  }

  // Método para actualizar el usuario en Firestore
  Future<void> updateUserInFirestore(String userId, String displayName) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'displayName': displayName,
      });
      //print("✅ Nombre de usuario actualizado en Firestore");
    } catch (e) {
      //print("❌ Error al actualizar Firestore: $e");
      rethrow;
    }
  }
}
