import 'package:finances/core/data/services/user_service.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/auth_error_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// Maneja almacenamiento local (token, estado de logout)
class AuthStorage {
  static const String _tokenKey = 'auth_token';
  static const String _loggedOutKey = 'user_logged_out';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> setLoggedOut(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedOutKey, value);
  }

  Future<bool> isLoggedOut() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedOutKey) ?? false;
  }

  Future<void> clearLoggedOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedOutKey);
  }
}

/// Provider de autenticación para usar en toda la app
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Estado general de la autenticación
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState.initial()
      : user = null,
        isLoading = false,
        error = null;

  const AuthState.loading()
      : user = null,
        isLoading = true,
        error = null;

  const AuthState.authenticated(this.user)
      : isLoading = false,
        error = null;

  const AuthState.unauthenticated()
      : user = null,
        isLoading = false,
        error = null;

  const AuthState.error(this.error)
      : user = null,
        isLoading = false;

  String? get uid => user?.uid;
  bool get isAuthenticated => user != null;
}

/// Controlador principal de autenticación
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final AuthStorage _storage = AuthStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;

  AuthNotifier() : super(const AuthState.initial()) {
    _initAuthListener();
  }

  @override
  void dispose() {
    // Cancelar suscripción para evitar memory leaks
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Escucha los cambios de sesión de Firebase con manejo mejorado
  void _initAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((User? user) async {
      try {
        if (user != null) {
          // Recargar usuario para obtener información actualizada
          await user.reload();
          final updatedUser = _auth.currentUser;

          if (updatedUser != null && updatedUser.uid == user.uid) {
            final token = await updatedUser.getIdToken();
            await _storage.saveToken(token ?? '');
            state = AuthState.authenticated(updatedUser);
          }
        } else {
          await _storage.deleteToken();
          state = const AuthState.unauthenticated();
        }
      } catch (error) {
        debugPrint('Error en authStateChanges: $error');
        // En caso de error, verificar manualmente el estado
        checkAuthStatus();
      }
    }, onError: (error) {
      debugPrint('Error en stream de autenticación: $error');
      state = AuthState.error(ErrorStrings.unexpectedError);
    });
  }

  /// Verificar manualmente el estado de autenticación
  Future<void> checkAuthStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        final token = await user.getIdToken();
        await _storage.saveToken(token ?? '');
        state = AuthState.authenticated(user);
      } else {
        await _storage.deleteToken();
        state = const AuthState.unauthenticated();
      }
    } catch (error) {
      debugPrint('Error al verificar estado de auth: $error');
      state = const AuthState.unauthenticated();
    }
  }

  /// Login con email y contraseña con timeout
  Future<void> signIn(String email, String password) async {
    try {
      state = const AuthState.loading();
      await _storage.clearLoggedOut();

      if (kIsWeb) {
        await _auth.setPersistence(Persistence.LOCAL);
        await _auth.setSettings(appVerificationDisabledForTesting: true);
      }

      // Timeout para evitar bloqueos infinitos
      final userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));

      await userCredential.user?.reload();
    } on TimeoutException {
      state = AuthState.error('Tiempo de espera agotado');
      throw 'Tiempo de espera agotado';
    } on FirebaseAuthException catch (e) {
      final message = AuthErrorHandler.handle(e);
      state = AuthState.error(message);
      throw message;
    } catch (_) {
      state = AuthState.error(ErrorStrings.unexpectedError);
      throw ErrorStrings.unexpectedError;
    }
  }

  /// Registro con email y contraseña
  Future<void> signUp(
    String name,
    String displayName,
    String email,
    String password,
  ) async {
    try {
      state = const AuthState.loading();
      await _storage.clearLoggedOut();

      await _userService.registerUser(
        name: name,
        displayName: displayName,
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      final message = AuthErrorHandler.handle(e);
      state = AuthState.error(message);
      throw message;
    } catch (_) {
      state = AuthState.error(ErrorStrings.unexpectedError);
      throw ErrorStrings.unexpectedError;
    }
  }

  /// Cierra la sesión
  /// Cierra la sesión
  Future<void> signOut() async {
    try {
      state = const AuthState.loading();

      // 🧹 1. Limpiar storage
      await _storage.setLoggedOut(true);
      await _storage.deleteToken();

      // 🚫 2. Cerrar sesión en Google (si aplica)
      try {
        await googleSignIn.signOut();
      } catch (e) {
        debugPrint('Google Sign-In no estaba activo o ya cerrado: $e');
      }

      // 🚫 3. Cerrar sesión en Firebase
      await _auth.signOut();

      // 🔄 4. Verificar que realmente se cerró
      if (_auth.currentUser != null) {
        debugPrint(
            '⚠️ Firebase currentUser aún existe después de signOut(). Forzando cierre.');
        await _auth.signOut();
      }

      // ✅ 5. Actualizar estado solo si realmente no hay usuario
      if (_auth.currentUser == null) {
        state = const AuthState.unauthenticated();
      } else {
        debugPrint('❌ ERROR: No se pudo cerrar sesión en Firebase.');
        state =
            AuthState.error('No se pudo cerrar sesión. Inténtalo de nuevo.');
        throw Exception('No se pudo cerrar sesión en Firebase.');
      }
    } catch (e) {
      debugPrint('Error en signOut: $e');
      await _storage.deleteToken();
      state = AuthState.error(ErrorStrings.unexpectedError);
      rethrow;
    }
  }

  /// Actualiza displayName en Firebase Auth y Firestore
  Future<void> updateDisplayName(String displayName) async {
    try {
      state = const AuthState.loading();
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.reload();
        await updateUserInFirestore(user.uid, displayName);
        state = AuthState.authenticated(_auth.currentUser!);
      }
    } catch (_) {
      state = AuthState.error(ErrorStrings.unexpectedError);
      throw ErrorStrings.unexpectedError;
    }
  }

  /// Actualiza displayName en Firestore
  Future<void> updateUserInFirestore(String userId, String displayName) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({'displayName': displayName});
  }

  /// LOGIN con Google con mejor manejo de tiempo
  Future<bool> signInWithGoogle() async {
    try {
      state = const AuthState.loading();

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        forceCodeForRefreshToken: true,
      );

      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser =
          await googleSignIn.signIn().timeout(const Duration(seconds: 15));

      if (googleUser == null) {
        state = const AuthState.unauthenticated();
        throw Exception("Inicio de sesión cancelado");
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 15));

      final user = userCredential.user;
      if (user == null) {
        state = const AuthState.unauthenticated();
        throw Exception("Usuario no encontrado");
      }

      final exists = await _userService.userExists(user.uid);
      state = AuthState.authenticated(user);

      return !exists;
    } on TimeoutException {
      state = AuthState.error('Tiempo de espera agotado');
      throw Exception('Tiempo de espera agotado');
    } catch (e) {
      state = AuthState.error(ErrorStrings.unexpectedError);
      debugPrint("Error en signInWithGoogle: $e");
      rethrow;
    }
  }
}
