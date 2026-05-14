// auth_provider.dart
// CORREGIDO:
// - Fix preload infinito
// - Limpieza de biometría al cambiar de usuario
// - Guardado de 'last_email' para login rápido
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
import 'package:finances/core/data/services/BiometricAuthService.dart';

/// 🚀 Maneja almacenamiento local (estado de logout y tutorial)
class AuthStorage {
  static const String _loggedOutKey = 'user_logged_out';
  static const String _tutorialKey = 'tutorial_seen';

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
  bool _isLoggingIn = false;

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
          // 🛡️ Si estamos en login/registro, permitimos la sesión sin verificar biometría
          if (_isLoggingIn) {
            await user.reload();
            state = AuthState.authenticated(user);
            return;
          }

          final isFirstLogin = await _checkIfFirstLogin(user.uid);
          final isBiometricsEnabled =
              await BiometricAuthService().isBiometricEnabled();

          if (isBiometricsEnabled) {
            await user.reload();
            state = AuthState.authenticated(user);
            debugPrint(
                '🔒 Biometría activada: sesión mantenida pero bloqueada');
          } else if (isFirstLogin) {
            await user.reload();
            state = AuthState.authenticated(user);
            debugPrint('🔓 Primer login: sesión mantenida sin biometría');
            await _markAsNotFirstLogin(user.uid);
          } else {
            // 🚫 Cerrar sesión si no cumple requisitos (biometría o primer login)
            await _auth.signOut();
            try {
              await googleSignIn.signOut();
            } catch (_) {}
            state = const AuthState.unauthenticated();
            debugPrint('🔒 Sesión cerrada por falta de biometría activada');
          }
        } else {
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

  /// 🔍 Verificar manualmente el estado (fallback)
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
      _isLoggingIn = true;
      state = const AuthState.loading();
      await _storage.clearLoggedOut();

      // 🔥 LIMPIEZA DE SEGURIDAD: Elimina configuración biométrica del usuario anterior
      // Esto evita que un nuevo usuario herede la biometría de otro.
      await BiometricAuthService().clearBiometricSetting();

      final userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));

      await userCredential.user?.reload();

      // ✅ ACTUALIZACIÓN DE ESTADO: Evita el preload infinito
      state = AuthState.authenticated(userCredential.user!);

      // 💾 GUARDAR CORREO: Para pre-rellenar en futuros logins
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_email', email);
    } on TimeoutException {
      state = AuthState.error('Tiempo de espera agotado');
      throw 'Tiempo de espera agotado';
    } on FirebaseAuthException catch (e) {
      final message = AuthErrorHandler.handle(e);
      state = AuthState.error(message);
      throw message;
    } finally {
      _isLoggingIn = false;
    }
  }

  /// 📝 Registro con email
  Future<void> signUp(
      String name, String displayName, String email, String password) async {
    try {
      _isLoggingIn = true;
      state = const AuthState.loading();
      await _storage.clearLoggedOut();

      // 🔥 LIMPIEZA DE SEGURIDAD: Igual que en signIn
      await BiometricAuthService().clearBiometricSetting();

      await _userService.registerUser(
        name: name,
        displayName: displayName,
        email: email,
        password: password,
      );

      final user = _auth.currentUser;
      if (user != null) {
        state = AuthState.authenticated(user);
        // 💾 GUARDAR CORREO DEL NUEVO USUARIO
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_email', email);
      } else {
        state = AuthState.error('Error al obtener usuario tras registro');
        throw Exception('Usuario no disponible tras registro');
      }
    } on FirebaseAuthException catch (e) {
      final message = AuthErrorHandler.handle(e);
      state = AuthState.error(message);
      throw message;
    } finally {
      _isLoggingIn = false;
    }
  }

  /// 🚪 Cerrar sesión
  Future<void> signOut() async {
    try {
      state = const AuthState.loading();
      await _storage.setLoggedOut(true);

      // 🔒 Limpia biometría al cerrar sesión manualmente
      await BiometricAuthService().clearBiometricSetting();

      try {
        await googleSignIn.signOut();
      } catch (_) {}
      await _auth.signOut();

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
      _isLoggingIn = true;
      state = const AuthState.loading();

      // 🔥 LIMPIEZA DE SEGURIDAD: También para Google Sign-In
      await BiometricAuthService().clearBiometricSetting();

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        forceCodeForRefreshToken: true,
      );

      await googleSignIn.signOut();
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

      state = AuthState.authenticated(user);

      // 💾 GUARDAR CORREO DE GOOGLE
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_email', user.email ?? '');

      final exists = await _userService.userExists(user.uid);
      return !exists;
    } on TimeoutException {
      state = AuthState.error('Tiempo de espera agotado');
      throw Exception('Tiempo de espera agotado');
    } catch (e) {
      state = AuthState.error(ErrorStrings.unexpectedError);
      rethrow;
    } finally {
      _isLoggingIn = false;
    }
  }

  /// ❌ Eliminar cuenta
  Future<void> deleteAccount({String? password}) async {
    _isProcessingDeletion = true;
    try {
      state = const AuthState.loading();
      await _userService.deleteAccount(password: password);
      await _auth.signOut();
      await _storage.setLoggedOut(true);
      try {
        await googleSignIn.signOut();
      } catch (_) {}
      state = const AuthState.unauthenticated();
    } on FirebaseAuthException catch (e) {
      final message = AuthErrorHandler.handle(e);
      _isProcessingDeletion = false;
      state = AuthState.error(message);
      throw message;
    } catch (e) {
      _isProcessingDeletion = false;
      final message = e is String ? e : ErrorStrings.unexpectedError;
      state = AuthState.error(message);
      throw message;
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

  // 🎯 API para tutorial
  Future<bool> checkTutorial() async => await _storage.isTutorialSeen();
  Future<void> markTutorialSeen() async => await _storage.setTutorialSeen(true);

  // ✅ Verifica si es el primer login del usuario
  Future<bool> _checkIfFirstLogin(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return false;
    final data = userDoc.data();
    return data?['firstLogin'] == true;
  }

  // ✅ Marca al usuario como no primer login
  Future<void> _markAsNotFirstLogin(String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({'firstLogin': false});
  }
}
