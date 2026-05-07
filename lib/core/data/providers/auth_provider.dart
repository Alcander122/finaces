import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finances/core/data/services/BiometricAuthService.dart';
import 'package:finances/core/data/services/user_service.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/auth_error_handler.dart';
import 'package:finances/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _loggedOutKey = 'user_logged_out';
  static const String _tutorialKey = 'tutorial_seen';
  static const String _lockedKey = 'app_locked';

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

  Future<void> setLocked(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockedKey, value);
  }

  Future<bool> isLocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lockedKey) ?? false;
  }

  Future<void> clearLocked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockedKey, false); // Forzamos el valor a falso
  }
}

class AuthState {
  final User? user;
  final bool isLoading;
  final bool isLocked;
  final String? error;

  const AuthState.initial()
      : user = null,
        isLoading = true,
        isLocked = false,
        error = null;
  const AuthState.loading()
      : user = null,
        isLoading = true,
        isLocked = false,
        error = null;
  const AuthState.authenticated(this.user)
      : isLoading = false,
        isLocked = false,
        error = null;
  const AuthState.locked(this.user)
      : isLoading = false,
        isLocked = true,
        error = null;
  const AuthState.unauthenticated()
      : user = null,
        isLoading = false,
        isLocked = false,
        error = null;
  const AuthState.error(this.error)
      : user = null,
        isLoading = false,
        isLocked = false;

  String? get uid => user?.uid;
  bool get isAuthenticated => user != null;
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final AuthStorage _storage = AuthStorage();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;
  bool isProcessingDeletion = false;
  bool isLoggingIn = false;
  Timer? _inactivityTimer;
  final Duration inactivityDuration = const Duration(minutes: 5);

  AuthNotifier() : super(const AuthState.initial()) {
    _initAuthListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _initAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((User? user) async {
      try {
        final isExplicitlyLoggedOut = await _storage.isLoggedOut();
        final wasLockedInStorage = await _storage.isLocked();

        if (user == null || isExplicitlyLoggedOut) {
          state = const AuthState.unauthenticated();
          return;
        }

        await user.reload();

        // 1. PRIORIDAD: ¿El disco dice que la app está bloqueada? (Tenga huella o no)
        if (wasLockedInStorage) {
          state = AuthState.locked(user);
          debugPrint("🔒 Persistencia: Iniciando en modo BLOQUEADO");
        } else {
          // 2. Si no estaba marcada como bloqueada, checar biometría para bloqueo preventivo
          final isBiometricEnabled =
              await BiometricAuthService().isBiometricEnabled();
          if (isBiometricEnabled) {
            await lockApp();
          } else {
            state = AuthState.authenticated(user);
            await _storage.clearLocked();
          }
        }

        _startInactivityTimer();
      } catch (e) {
        state = const AuthState.unauthenticated();
      }
    });
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityDuration, lockApp);
  }

  void resetInactivityTimer() {
    if (state.isAuthenticated && !state.isLocked) {
      _startInactivityTimer();
    }
  }

  Future<void> lockApp() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      // Guardar en disco SIEMPRE, sin importar la configuración de huella
      await _storage.setLocked(true);
      state = AuthState.locked(currentUser);

      // Limpiar navegación
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
      debugPrint("🔒 APP BLOQUEADA (Guardado en SharedPreferences)");
    }
  }

  // --- FUNCIONES DE AUTENTICACIÓN ---

  Future<bool> unlockWithBiometrics() async {
    try {
      final status = await BiometricAuthService().authenticateWithStatus();
      if (status == BiometricAuthStatus.success && _auth.currentUser != null) {
        await _storage.clearLocked();
        state = AuthState.authenticated(_auth.currentUser!);
        _startInactivityTimer();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> unlockWithPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) throw Exception();

      final credential =
          EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(credential);

      await _storage.clearLocked();
      state = AuthState.authenticated(user);
      _startInactivityTimer();
    } catch (e) {
      state = AuthState.locked(_auth.currentUser);
      throw Exception("Contraseña incorrecta");
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      isLoggingIn = true;
      state = const AuthState.loading();
      await _storage.clearLoggedOut();
      await _storage.clearLocked();
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      state = AuthState.authenticated(credential.user!);
      _startInactivityTimer();
    } on FirebaseAuthException catch (e) {
      state = AuthState.error(AuthErrorHandler.handle(e));
      rethrow;
    } finally {
      isLoggingIn = false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      isLoggingIn = true;
      state = const AuthState.loading();
      await _storage.clearLoggedOut();
      await _storage.clearLocked();
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        state = const AuthState.unauthenticated();
        throw Exception("Login cancelado");
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      state = AuthState.authenticated(userCredential.user!);
      _startInactivityTimer();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_email', userCredential.user!.email ?? '');
      return !(await _userService.userExists(userCredential.user!.uid));
    } catch (e) {
      state = AuthState.error(ErrorStrings.unexpectedError);
      rethrow;
    } finally {
      isLoggingIn = false;
    }
  }

  Future<void> signUp(
      String name, String displayName, String email, String password) async {
    try {
      isLoggingIn = true;
      state = const AuthState.loading();
      await _storage.clearLoggedOut();
      await _storage.clearLocked();
      await _userService.registerUser(
          name: name,
          displayName: displayName,
          email: email,
          password: password);
      if (_auth.currentUser != null) {
        state = AuthState.authenticated(_auth.currentUser!);
        _startInactivityTimer();
      }
    } on FirebaseAuthException catch (e) {
      state = AuthState.error(AuthErrorHandler.handle(e));
      rethrow;
    } finally {
      isLoggingIn = false;
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    try {
      state = const AuthState.loading();
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.reload();
        await firestore
            .collection('users')
            .doc(user.uid)
            .update({'displayName': displayName});
        state = AuthState.authenticated(_auth.currentUser!);
      }
    } catch (e) {
      state = AuthState.error(ErrorStrings.unexpectedError);
    }
  }

  Future<void> deleteAccount(String password) async {
    try {
      isProcessingDeletion = true;
      state = const AuthState.loading();
      await _userService.deleteAccount(password);
      await _storage.setLoggedOut(true);
      await _storage.clearLocked();
      await _auth.signOut();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error("Error eliminando cuenta");
      rethrow;
    } finally {
      isProcessingDeletion = false;
    }
  }

  Future<void> signOut() async {
    try {
      state = const AuthState.loading();
      await _storage.setLoggedOut(true);
      await _storage.clearLocked();
      await googleSignIn.signOut();
      await _auth.signOut();
      _inactivityTimer?.cancel();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error("Error cerrando sesión");
    }
  }
}
