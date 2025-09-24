// auth_provider.dart (CORREGIDO - PERMITE PRIMER LOGIN SIN BIOMETRÍA)
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
import 'package:finances/core/data/services/BiometricAuthService.dart'; // Import para BiometricAuthService

/// 🚀 Maneja almacenamiento local (estado de logout y tutorial)
class AuthStorage {
  static const String _loggedOutKey = 'user_logged_out';
  static const String _tutorialKey =
      'tutorial_seen'; // CLAVE UNIFICADA para el tutorial

  // 🚪 Estado de logout (para saber si el usuario cerró sesión manualmente)
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

  // 🎯 Control de tutorial (para mostrar el tutorial solo la primera vez)
  Future<void> setTutorialSeen(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, value);
  }

  Future<bool> isTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialKey) ?? false;
  }
}

/// 🌍 Provider de autenticación global
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// 📌 Estado general de autenticación
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

/// 🔑 Controlador principal de autenticación
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final AuthStorage _storage = AuthStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;
  bool _isProcessingDeletion = false;
  bool _isLoggingIn = false; // 🆕 NUEVO FLAG: Evita verificación de biometría durante login/registro
  // 🆕 FLAG: Detecta si es el primer login del usuario (eliminado porque no se usa)

  AuthNotifier() : super(const AuthState.initial()) {
    _initAuthListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// 👂 Escucha cambios de sesión de Firebase
  void _initAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((User? user) async {
      try {
        if (_isProcessingDeletion && user == null) {
          _isProcessingDeletion = false;
          debugPrint('✅ Usuario eliminado correctamente');
        }

        if (user != null) {
          // 🚨 CORRECCIÓN CLAVE: Si estamos en proceso de login o registro,
          // omitimos verificación de biometría para mantener la sesión
          if (_isLoggingIn) {
            await user.reload();
            state = AuthState.authenticated(user);
            return; // Salimos aquí, sin verificar biometría
          }

          // ✅ Verificamos si es el primer login del usuario
          final isFirstLogin = await _checkIfFirstLogin(user.uid);

          // ✅ Verificamos biometría solo si NO estamos en proceso de login/registro
          final isBiometricsEnabled =
              await BiometricAuthService().isBiometricEnabled();

          if (isBiometricsEnabled) {
            // 🛑 BIOMETRÍA ACTIVADA: Mantenemos la sesión en Firebase
            await user.reload();
            state = AuthState.authenticated(user);
            debugPrint(
                '🔒 Biometría activada: sesión mantenida pero bloqueada');
          } else if (isFirstLogin) {
            // ✅ PRIMER LOGIN: Permitimos la sesión aunque no haya biometría
            await user.reload();
            state = AuthState.authenticated(user);
            debugPrint('🔓 Primer login: sesión mantenida sin biometría');
            // Marcar como no primer login para futuras sesiones
            await _markAsNotFirstLogin(user.uid);
          } else {
            // 🚫 BIOMETRÍA DESACTIVADA Y NO ES PRIMER LOGIN: Cerramos sesión completamente
            await _auth.signOut(); // ⚠️ Esto elimina la sesión de Firebase
            await googleSignIn.signOut(); // Limpia sesión de Google si existe
            state = const AuthState.unauthenticated();
            debugPrint('🔒 Sesión cerrada por falta de biometría activada');
          }
        } else {
          // Si no hay usuario, estado es unauthenticated
          state = const AuthState.unauthenticated();
        }
      } catch (error) {
        debugPrint('⚠️ Error en authStateChanges: $error');
        checkAuthStatus();
      }
    }, onError: (error) {
      debugPrint('⚠️ Error en stream de auth: $error');
      state = AuthState.error(ErrorStrings.unexpectedError);
    });
  }

  /// 🔍 Verificar manualmente el estado (usado cuando hay errores en el listener)
  Future<void> checkAuthStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  /// 📧 Login con email y contraseña
  Future<void> signIn(String email, String password) async {
    try {
      _isLoggingIn = true; // 🚨 ACTIVAR FLAG DURANTE LOGIN
      state = const AuthState.loading();
      await _storage.clearLoggedOut(); // Limpia estado de logout manual

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
    } finally {
      _isLoggingIn = false; // 🚨 DESACTIVAR FLAG AL FINALIZAR
    }
  }

  /// 📝 Registro con email
  Future<void> signUp(
      String name, String displayName, String email, String password) async {
    try {
      _isLoggingIn = true; // 🚨 ACTIVAR FLAG DURANTE REGISTRO
      state = const AuthState.loading();
      await _storage.clearLoggedOut();

      // ✅ Usa UserService para registrar (esto crea el usuario y guarda en Firestore)
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
    } finally {
      _isLoggingIn = false; // 🚨 DESACTIVAR FLAG AL FINALIZAR
    }
  }

  /// 🚪 Cerrar sesión
  Future<void> signOut() async {
    try {
      state = const AuthState.loading();
      await _storage.setLoggedOut(true); // Marca como logout manual
      try {
        await googleSignIn.signOut(); // Cierra sesión de Google
      } catch (_) {}
      await _auth.signOut(); // Cierra sesión de Firebase
      if (_auth.currentUser == null) {
        state = const AuthState.unauthenticated();
      } else {
        state = AuthState.error('No se pudo cerrar sesión');
      }
    } catch (e) {
      state = AuthState.error(ErrorStrings.unexpectedError);
      rethrow;
    }
  }

  /// ✏️ Actualiza displayName en Firebase + Firestore
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

  Future<void> updateUserInFirestore(String userId, String displayName) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({'displayName': displayName});
  }

  /// 🔑 Login con Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoggingIn = true; // 🚨 ACTIVAR FLAG DURANTE LOGIN CON GOOGLE
      state = const AuthState.loading();

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        forceCodeForRefreshToken: true,
      );

      await googleSignIn.signOut(); // forzar login limpio
      final googleUser =
          await googleSignIn.signIn().timeout(const Duration(seconds: 15));

      if (googleUser == null) {
        state = const AuthState.unauthenticated();
        throw Exception("Inicio cancelado");
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 15));

      final user = userCredential.user;
      if (user == null) throw Exception("Usuario no encontrado");

      final exists = await _userService.userExists(user.uid);
      state = AuthState.authenticated(user);

      return !exists; // devuelve true si es nuevo
    } on TimeoutException {
      state = AuthState.error('Tiempo de espera agotado');
      throw Exception('Tiempo de espera agotado');
    } catch (e) {
      state = AuthState.error(ErrorStrings.unexpectedError);
      rethrow;
    } finally {
      _isLoggingIn = false; // 🚨 DESACTIVAR FLAG AL FINALIZAR
    }
  }

  /// ❌ Eliminar cuenta
  Future<void> deleteAccount(String password) async {
    _isProcessingDeletion = true;
    try {
      state = const AuthState.loading();
      await _userService.deleteAccount(password);
      await _auth.signOut();
      await _storage.setLoggedOut(true);
      try {
        await googleSignIn.signOut();
      } catch (_) {}
      state = const AuthState.unauthenticated();
    } catch (e) {
      _isProcessingDeletion = false;
      state = AuthState.error("Error al eliminar cuenta");
      rethrow;
    }
  }

  /// 📩 Enviar reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      final message = AuthErrorHandler.handle(e);
      throw Exception(message);
    }
  }

  // 🎯 API para tutorial desde la UI
  Future<bool> checkTutorial() async => await _storage.isTutorialSeen();
  Future<void> markTutorialSeen() async => await _storage.setTutorialSeen(true);

  // ✅ NUEVO: Verifica si es el primer login del usuario
  Future<bool> _checkIfFirstLogin(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return false;
    final data = userDoc.data();
    return data?['firstLogin'] == true;
  }

  // ✅ NUEVO: Marca al usuario como no primer login
  Future<void> _markAsNotFirstLogin(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'firstLogin': false,
    });
  }
}
