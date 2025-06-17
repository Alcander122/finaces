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
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Esta clase se encarga de gestionar el almacenamiento local del token de autenticación
/// y el estado del usuario (por ejemplo, si está logueado o cerró sesión).
class AuthStorage {
  static const String _tokenKey = 'auth_token';
  static const String _loggedOutKey = 'user_logged_out';

  // Guarda el token de autenticación en SharedPreferences.
  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e, stack) {
      logger.e('Error saving token', error: e, stackTrace: stack);
      throw ErrorStrings.unexpectedError;
    }
  }

  // Elimina el token de autenticación.
  Future<void> deleteToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e, stack) {
      logger.e('Error deleting token', error: e, stackTrace: stack);
      throw ErrorStrings.unexpectedError;
    }
  }

  // Obtiene el token almacenado.
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e, stack) {
      logger.e('Error getting token', error: e, stackTrace: stack);
      return null;
    }
  }

  // Marca al usuario como cerrado de sesión.
  Future<void> setLoggedOut(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loggedOutKey, value);
    } catch (e, stack) {
      logger.e('Error setting logged out flag', error: e, stackTrace: stack);
      throw ErrorStrings.unexpectedError;
    }
  }

  // Verifica si el usuario está marcado como deslogueado.
  Future<bool> isLoggedOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_loggedOutKey) ?? false;
    } catch (e, stack) {
      logger.e('Error checking logged out flag', error: e, stackTrace: stack);
      return false;
    }
  }

  // Limpia la marca de cierre de sesión.
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

/// Proveedor de estado para la autenticación utilizando Riverpod.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Define el estado de autenticación de la aplicación.
class AuthState {
  /// Usuario autenticado (si existe).
  final User? user;
  /// Indica si se está realizando una operación (cargando).
  final bool isLoading;
  /// Mensaje de error (si ocurre alguno).
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

/// Clase que gestiona la lógica de autenticación con Firebase.
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService(); // Servicio para manejar operaciones de usuario en Firestore.
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final AuthStorage _storage = AuthStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthNotifier() : super(const AuthState.initial()) {
    _initAuthListener();
  }

  /// Inicializa un listener para detectar los cambios en el estado de autenticación.
  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      try {
        state = const AuthState.loading();
        if (user != null) {
          // Actualiza el usuario y guarda el token.
          await user.reload();
          final updatedUser = _auth.currentUser;
          if (updatedUser != null) {
            final token = await updatedUser.getIdToken();
            await _storage.saveToken(token ?? '');
            state = AuthState.authenticated(updatedUser);
          }
        } else {
          // Si el usuario es nulo, se elimina el token y se marca como no autenticado.
          await _storage.deleteToken();
          state = const AuthState.unauthenticated();
        }
      } catch (e) {
        state = AuthState.error(ErrorStrings.unexpectedError);
      }
    });
  }

  /// Inicio de sesión con email y contraseña.
  Future<void> signIn(String email, String password) async {
    try {
      state = const AuthState.loading();
      await _storage.clearLoggedOut();

      // Para la plataforma web se configura la persistencia y se deshabilita appVerification en testing
      if (kIsWeb) {
        await _auth.setPersistence(Persistence.LOCAL);
        await _auth.setSettings(appVerificationDisabledForTesting: true);
      }
      // Se realiza el inicio de sesión con correo y contraseña.
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

  /// Registro de usuario: se registra en Firebase Auth y se guarda la información en Firestore.
  Future<void> signUp(String name, String displayName, String email, String password) async {
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

  /// Cierre de sesión: se cierra la sesión en Firebase Auth y se eliminan las marcas locales.
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

  /// Actualiza el nombre desplegado del usuario y lo actualiza en Firestore.
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

  /// Actualiza la información del usuario en la colección 'users' de Firestore.
  Future<void> updateUserInFirestore(String userId, String displayName) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'displayName': displayName,
      });
    } catch (e) {
      throw ErrorStrings.unexpectedError;
    }
  }

  /// Inicio de sesión con Google.
  Future<void> signInWithGoogle() async {
    try {
      state = const AuthState.loading();
      await _storage.clearLoggedOut();

      // Inicia el flujo de autenticación con Google.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Si el usuario cancela el proceso.
        throw FirebaseAuthException(
          code: 'aborted-by-user',
          message: 'Sign in aborted by user',
        );
      }
      // Recibe la autenticación y crea el credential de Firebase.
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user != null) {
        await _handleNewGoogleUser(user); // Crea el usuario en Firestore si es nuevo.
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

  /// Verifica en Firestore si el usuario autenticado mediante Google ya existe, y, en caso negativo, lo registra.
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
      // Se puede registrar el error en consola o logger, pero no se interrumpe el flujo.
      logger.e('Error al sincronizar datos de usuario', error: e);
    }
  }
  /// Inicio de sesión con Facebook
  Future<void> signInWithFacebook() async {
    try {
      state = const AuthState.loading();
      await _storage.clearLoggedOut();

      // Iniciar flujo de autenticación con Facebook
      final LoginResult loginResult = await FacebookAuth.instance.login();

      if (loginResult.status != LoginStatus.success) {
        throw FirebaseAuthException(
          code: 'aborted-by-user',
          message: 'Sign in aborted by user',
        );
      }

      // Obtener token de acceso
      final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);

      // Iniciar sesión en Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(facebookAuthCredential);
      final User? user = userCredential.user;

      if (user != null) {
        await _handleNewSocialUser(user); // Verificar/crear usuario en Firestore
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

  /// Maneja usuarios nuevos de redes sociales (Google/Facebook)
  Future<void> _handleNewSocialUser(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? 'Usuario Social',
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      logger.e('Error al sincronizar datos de usuario social', error: e);
    }
  }
}