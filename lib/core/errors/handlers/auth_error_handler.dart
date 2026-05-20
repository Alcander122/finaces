import 'package:finances/core/errors/error_strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Traduce errores de Firebase Auth a mensajes amigables UX
class AuthErrorHandler {
  static String handle(FirebaseAuthException error) {
    debugPrint("🔥 Auth Error Catch: [${error.code}] - ${error.message}");

    switch (error.code.toLowerCase()) {
      case 'invalid-email':
        return ErrorStrings.invalidEmail;
      case 'user-disabled':
        return ErrorStrings.unexpectedError;
      case 'user-not-found':
        return ErrorStrings.userNotFound;
      case 'wrong-password':
      case 'invalid-credential':
        return ErrorStrings.invalidCredentials;
      case 'email-already-in-use':
        return ErrorStrings.emailInUse;
      case 'operation-not-allowed':
        return ErrorStrings.authMethodDisabled;
      case 'weak-password':
        return ErrorStrings.weakPassword;
      case 'too-many-requests':
        return ErrorStrings.passwordResetTooManyRequests;
      case 'network-request-failed':
        return ErrorStrings.networkError;
      case 'aborted-by-user':
        return ErrorStrings.authCancelled;
      default:
        // En producción nunca mostramos el código técnico al usuario
        return kDebugMode
            ? "${ErrorStrings.unexpectedError} (${error.code})"
            : ErrorStrings.unexpectedError;
    }
  }
}
