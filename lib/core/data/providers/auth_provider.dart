import 'package:finances/core/data/services/user_service.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/auth_error_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

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

  AuthNotifier() : super(const AuthState.initial()) {
    _initAuthListener();
  }

  /// Escucha los cambios de sesión de Firebase
  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      try {
        if (user != null) {
          await user.reload();
          final updatedUser = _auth.currentUser;
          if (updatedUser != null) {
            final token = await updatedUser.getIdToken();
            await _storage.saveToken(token ?? '');
            state = AuthState.authenticated(updatedUser);
          }
        } else {
          await _storage.deleteToken();
          state = const AuthState.unauthenticated();
        }
      } catch (_) {
        state = AuthState.error(ErrorStrings.unexpectedError);
      }
    });
  }

  /// Login con email y contraseña
  Future<void> signIn(String email, String password) async {
    try {
      state = const AuthState.loading();
      await _storage.clearLoggedOut();

      if (kIsWeb) {
        await _auth.setPersistence(Persistence.LOCAL);
        await _auth.setSettings(appVerificationDisabledForTesting: true);
      }

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _auth.currentUser?.reload();
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
  Future<void> signOut() async {
    try {
      state = const AuthState.loading();
      await _storage.setLoggedOut(true);
      await _auth.signOut();
      await _storage.deleteToken();
      state = const AuthState.unauthenticated();
    } catch (_) {
      await _storage.deleteToken();
      state = AuthState.error(ErrorStrings.unexpectedError);
      throw ErrorStrings.unexpectedError;
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

  /// LOGIN con Google (no crea documento si es nuevo)
  ///
  /// Retorna `true` si el usuario NO tiene documento en Firestore (es nuevo)
  Future<bool> signInWithGoogle() async {
    try {
      // Crear una nueva instancia para asegurar el selector de cuenta
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // Esto fuerza una nueva autenticación, evitando sesión previa
        forceCodeForRefreshToken: true,
      );

      // Cierra cualquier sesión previa para que siempre salga el diálogo
      await googleSignIn.signOut();

      // Muestra el diálogo de selección de cuenta de Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception("Inicio de sesión cancelado");

      // Autenticación con Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Genera las credenciales de Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Inicia sesión en Firebase con las credenciales de Google
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception("Usuario no encontrado");

      // Verifica si el documento del usuario ya existe en Firestore
      final exists = await _userService.userExists(user.uid);

      // Si no existe, se debe redirigir al registro
      return !exists;
    } catch (e) {
      debugPrint("Error en signInWithGoogle: $e");
      rethrow;
    }
  }

  /// Login con Facebook
  /*Future<void> signInWithFacebook() async {
    try {
      state = const AuthState.loading();
      await _storage.clearLoggedOut();

      final result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) {
        throw FirebaseAuthException(code: 'aborted-by-user');
      }

      final credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final token = await user.getIdToken();
        await _storage.saveToken(token ?? '');
        state = AuthState.authenticated(user);
      }
    } on FirebaseAuthException catch (e) {
      final message = AuthErrorHandler.handle(e);
      state = AuthState.error(message);
      throw message;
    } catch (_) {
      state = AuthState.error(ErrorStrings.unexpectedError);
      throw ErrorStrings.unexpectedError;
    }
  }*/
}
