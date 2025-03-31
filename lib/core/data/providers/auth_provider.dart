// auth_provider.dart
// ignore_for_file: depend_on_referenced_packages
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/auth_error_handler.dart';
import 'package:finances/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';

class AuthStorage {
  static const String _tokenKey = 'auth_token';
  static const String _loggedOutKey = 'user_logged_out';

  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e, stack) {
      logger.e('Error saving token', error: e, stackTrace: stack);
      //print("Error saving token, error: $e, stackTrace: $stack");
      throw ErrorStrings.unexpectedError;
    }
  }

  Future<void> deleteToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e, stack) {
      logger.e('Error deleting token', error: e, stackTrace: stack);
      //print("Error deleting token, error: $e, stackTrace: $stack");
      throw ErrorStrings.unexpectedError;
    }
  }

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e, stack) {
      logger.e('Error getting token', error: e, stackTrace: stack);
      return null;
    }
  }

  Future<void> setLoggedOut(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loggedOutKey, value);
      //print('Logged out flag set to: $value');
    } catch (e, stack) {
      logger.e('Error setting logged out flag', error: e, stackTrace: stack);
      //print("Error setting logged out flag, error: $e, stackTrace: $stack");
      throw ErrorStrings.unexpectedError;
    }
  }

  Future<bool> isLoggedOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_loggedOutKey) ?? false;
    } catch (e, stack) {
      logger.e('Error checking logged out flag', error: e, stackTrace: stack);
      return false;
    }
  }

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

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final AuthStorage _storage = AuthStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthNotifier() : super(const AuthState.initial()) {
    _initAuthListener();
  }

  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      try {
        state = const AuthState.loading();
        bool loggedOut = await _storage.isLoggedOut();

        if (user != null) {
          final token = await user.getIdToken();
          await _storage
              .saveToken(token ?? ''); // 🔹 Aquí corregimos el posible null

          state = AuthState.authenticated(user);
          logger.i(
              'Usuario autenticado: ${user.email ?? 'Desconocido'}'); // 🔹 Evita null en email
        } else {
          await _forceTokenDeletion();
          state = const AuthState.unauthenticated();
        }
      } catch (e, stack) {
        logger.e('Error en authStateChanges', error: e, stackTrace: stack);
        state = AuthState.error(ErrorStrings.unexpectedError);
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    try {
      state = const AuthState.loading();
      // Al iniciar sesión, limpiamos el flag de logout.
      await _storage.clearLoggedOut();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      logger.i('Inicio de sesión exitoso: $email');
    } on FirebaseAuthException catch (e) {
      final message = AuthErrorHandler.handle(e);
      state = AuthState.error(message);
      throw message;
    } catch (e, stack) {
      logger.e('Error general en signIn', error: e, stackTrace: stack);
      state = AuthState.error(ErrorStrings.unexpectedError);
      throw ErrorStrings.unexpectedError;
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    try {
      state = const AuthState.loading();
      await _storage.clearLoggedOut();
      await _userService.registerUser(
          name: name, email: email, password: password);
      logger.i('Registro exitoso: $email');
    } on FirebaseAuthException catch (e) {
      final message = AuthErrorHandler.handle(e);
      state = AuthState.error(message);
      throw message;
    } catch (e, stack) {
      logger.e('Error general en signUp', error: e, stackTrace: stack);
      state = AuthState.error(ErrorStrings.unexpectedError);
      throw ErrorStrings.unexpectedError;
    }
  }

  Future<void> _forceTokenDeletion() async {
    try {
      await _storage.deleteToken();
      //logger.i('Limpieza de token forzada exitosa');
      //print('Limpieza de token forzada exitosa');
    } catch (e, stack) {
      logger.e('Error en limpieza forzada', error: e, stackTrace: stack);
      // print("Error en limpieza forzada, error: $e, stackTrace: $stack");
    }
  }

  Future<void> signOut() async {
    try {
      state = const AuthState.loading();
      // Establecer el flag para indicar que el usuario cerró sesión manualmente.
      await _storage.setLoggedOut(true);
      await _auth.signOut();
      await _storage.deleteToken();

      // Verificación adicional para confirmar la eliminación.
      final currentUser = _auth.currentUser;
      final token = await _storage.getToken();

      if (currentUser == null && token == null) {
        state = const AuthState.unauthenticated();
        logger.i('Sesión cerrada completamente');
        //print('Sesión cerrada completamente');
      } else {
        throw ErrorStrings.unexpectedError;
      }
    } catch (e, stack) {
      logger.e('Error crítico en signOut', error: e, stackTrace: stack);
      //print("Error crítico en signOut, error: $e, stackTrace: $stack");
      await _forceTokenDeletion();
      state = AuthState.error(ErrorStrings.unexpectedError);
      throw ErrorStrings.unexpectedError;
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    try {
      state = const AuthState.loading();
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.reload();
        await updateUserInFirestore(user.uid, displayName);
        state = AuthState.authenticated(_auth.currentUser!);
        logger.i('Nombre actualizado: $displayName');
      }
    } catch (e, stack) {
      logger.e('Error en updateDisplayName', error: e, stackTrace: stack);
      state = AuthState.error(ErrorStrings.unexpectedError);
      throw ErrorStrings.unexpectedError;
    }
  }

  Future<void> updateUserInFirestore(String userId, String displayName) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'displayName': displayName,
      });
      logger.i('Firestore actualizado para usuario: $userId');
    } catch (e, stack) {
      logger.e('Error en updateUserInFirestore', error: e, stackTrace: stack);
      throw ErrorStrings.unexpectedError;
    }
  }
}

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
}
