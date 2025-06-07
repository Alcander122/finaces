import 'package:finances/core/data/services/user_service.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/auth_error_handler.dart';
import 'package:finances/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Clase para manejar el almacenamiento local de tokens y estado de autenticación
class AuthStorage {
  static const String _tokenKey = 'auth_token';
  static const String _loggedOutKey = 'user_logged_out';

  // Guarda el token de autenticación
  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e, stack) {
      logger.e('Error saving token', error: e, stackTrace: stack);
      throw ErrorStrings.unexpectedError;
    }
  }

  // Elimina el token de autenticación
  Future<void> deleteToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e, stack) {
      logger.e('Error deleting token', error: e, stackTrace: stack);
      throw ErrorStrings.unexpectedError;
    }
  }

  // Obtiene el token almacenado
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e, stack) {
      logger.e('Error getting token', error: e, stackTrace: stack);
      return null;
    }
  }

  // Marca al usuario como cerrado de sesión
  Future<void> setLoggedOut(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loggedOutKey, value);
    } catch (e, stack) {
      logger.e('Error setting logged out flag', error: e, stackTrace: stack);
      throw ErrorStrings.unexpectedError;
    }
  }

  // Verifica si el usuario está marcado como cerrado de sesión
  Future<bool> isLoggedOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_loggedOutKey) ?? false;
    } catch (e, stack) {
      logger.e('Error checking logged out flag', error: e, stackTrace: stack);
      return false;
    }
  }

  // Limpia la marca de cierre de sesión
  Future<void> clearLoggedOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loggedOutKey);
    } catch (e, stack) {
      logger.e('Error clearing logged out flag', error: e, stackTrace: stack);
      throw ErrorStrings.unexpectedError;
    }
  }
}

/// Proveedor de estado para autenticación (Riverpod)
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Clase que define el estado de autenticación
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

  String? get uid => user?.uid ?? '';
  bool get isAuthenticated => user != null;
}

/// Clase principal para manejar la lógica de autenticación
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final AuthStorage _storage = AuthStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthNotifier() : super(const AuthState.initial()) {
    _initAuthListener();
  }

  // Inicializa el listener de cambios de estado de autenticación
  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      try {
        state = const AuthState.loading();
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
      } catch (e) {
        state = AuthState.error(ErrorStrings.unexpectedError);
      }
    });
  }

  // Inicio de sesión con email y contraseña
  Future<void> signIn(String email, String password) async {
    try {
      state = const AuthState.loading();
      await _storage.clearLoggedOut();
      if (kIsWeb) {
        await _auth.setPersistence(Persistence.LOCAL);
        await _auth.setSettings(appVerificationDisabledForTesting: false);
      }
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = _auth.currentUser;
      if (user != null) await user.reload();
    } on FirebaseAuthException catch (e) {
      final message = AuthErrorHandler.handle(e);
      state = AuthState.error(message);
      throw message;
    } catch (e) {
      state = AuthState.error(ErrorStrings.unexpectedError);
      throw ErrorStrings.unexpectedError;
    }
  }

  // Registro de usuario
  Future<void> signUp(
      String name, String displayName, String email, String password) async {
    try {
      state = const AuthState.loading();
      await _storage.clearLoggedOut();
      await _userService.registerUser(
          name: name,
          displayName: displayName,
          email: email,
          password: password);
    } on FirebaseAuthException catch (e) {
      final message = AuthErrorHandler.handle(e);
      state = AuthState.error(message);
      throw message;
    } catch (e) {
      state = AuthState.error(ErrorStrings.unexpectedError);
      throw ErrorStrings.unexpectedError;
    }
  }

  // Cierre de sesión
  Future<void> signOut() async {
    try {
      state = const AuthState.loading();
      await _storage.setLoggedOut(true);
      await _auth.signOut();
      await _storage.deleteToken();
      final currentUser = _auth.currentUser;
      final token = await _storage.getToken();
      if (currentUser == null && token == null) {
        state = const AuthState.unauthenticated();
      } else {
        throw ErrorStrings.unexpectedError;
      }
    } catch (e) {
      await _storage.deleteToken();
      state = AuthState.error(ErrorStrings.unexpectedError);
      throw ErrorStrings.unexpectedError;
    }
  }

  // Actualización del nombre de usuario
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
    } catch (e) {
      state = AuthState.error(ErrorStrings.unexpectedError);
      throw ErrorStrings.unexpectedError;
    }
  }

  // Actualización en Firestore
  Future<void> updateUserInFirestore(String userId, String displayName) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'displayName': displayName,
      });
    } catch (e) {
      throw ErrorStrings.unexpectedError;
    }
  }

  // Inicio de sesión con Google
  Future<void> signInWithGoogle() async {
    try {
      state = const AuthState.loading();
      await _storage.clearLoggedOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'aborted-by-user',
          message: 'Sign in aborted by user',
        );
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user != null) {
        await _handleNewGoogleUser(user);
        final token = await user.getIdToken();
        await _storage.saveToken(token ?? '');
        state = AuthState.authenticated(user);
      }
    } on FirebaseAuthException catch (e) {
      final message = AuthErrorHandler.handle(e);
      state = AuthState.error(message);
      throw message;
    } catch (e) {
      state = AuthState.error(ErrorStrings.unexpectedError);
      throw ErrorStrings.unexpectedError;
    }
  }

  // Manejo de nuevos usuarios de Google
  Future<void> _handleNewGoogleUser(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'displayName': user.displayName ?? 'Usuario Nuevo',
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // logger.e('Error al sincronizar datos de usuario', error: e);
    }
  }
}
