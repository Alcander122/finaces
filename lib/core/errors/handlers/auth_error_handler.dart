import 'package:finances/core/errors/error_strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthErrorHandler {
  static String handle(FirebaseAuthException error) {
    debugPrint("[Firebase Auth] Código de error: ${error.code}");

    switch (error.code.toLowerCase()) {
      case 'invalid-email':
        return ErrorStrings.invalidEmail;
      case 'user-disabled':
        return "Cuenta deshabilitada. Contacta al soporte";
      case 'user-not-found':
        return ErrorStrings.userNotFound;
      case 'wrong-password':
        return ErrorStrings.wrongPassword;
      case 'email-already-in-use':
        return ErrorStrings.emailInUse;
      case 'operation-not-allowed':
        return "Método de autenticación no habilitado";
      case 'weak-password':
        return ErrorStrings.weakPassword;
      case 'network-request-failed':
        return ErrorStrings.networkError;
      case 'too-many-requests':
        return "Demasiados intentos. Intenta más tarde";
      default:
        return "${ErrorStrings.unexpectedError} (${error.code})";
    }
  }
}
