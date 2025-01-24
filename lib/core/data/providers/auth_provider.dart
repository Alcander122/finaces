import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';

class AuthStorage {
  static const String _tokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      print("✅ Token guardado exitosamente");
    } catch (e) {
      print("❌ Error al guardar el token: $e");
    }
  }

  Future<void> deleteToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      print("✅ Token eliminado");
    } catch (e) {
      print("❌ Error al eliminar el token: $e");
    }
  }

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print("❌ Error al obtener el token: $e");
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
        print(
            "🔄 Estado de autenticación actualizado: ${user?.email ?? 'Desconectado'}");
      } catch (e) {
        print("❌ Error en authStateChanges: $e");
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      print("✅ Inicio de sesión exitoso para: $email");
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      print("❌ Error inesperado al iniciar sesión: $e");
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    try {
      await _userService.registerUser(
          name: name, email: email, password: password);
      print("✅ Registro exitoso para: $email");
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      print("❌ Error inesperado al registrar usuario: $e");
      throw e;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _storage.deleteToken();
      state = null;
      print("✅ Sesión cerrada exitosamente");
    } catch (e) {
      print("❌ Error al cerrar sesión: $e");
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
    print("❌ $errorMessage");
    throw errorMessage;
  }
}
