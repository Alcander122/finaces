import 'package:finances/core/errors/error_strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Traduce errores de Firebase Auth a mensajes amigables
class AuthErrorHandler {
  static String handle(FirebaseAuthException error) {
    debugPrint("Error Firebase Auth: ${error.code}");

    switch (error.code.toLowerCase()) {
      case 'invalid-email':
        return ErrorStrings.invalidEmail;
      case 'user-disabled':
        return "Cuenta deshabilitada";
      case 'user-not-found':
        return ErrorStrings.userNotFound;
      case 'wrong-password':
        return ErrorStrings.wrongPassword;
      case 'email-already-in-use':
        return ErrorStrings.emailInUse;
      case 'operation-not-allowed':
        return "Método no habilitado";
      case 'weak-password':
        return ErrorStrings.weakPassword;
      case 'too-many-requests':
        return ErrorStrings.passwordResetTooManyRequests;
      case 'network-request-failed':
        return ErrorStrings.networkError;
      case 'aborted-by-user':
        return "Proceso cancelado por el usuario";
      default:
        return "${ErrorStrings.unexpectedError} (${error.code})";
    }
  }
}
