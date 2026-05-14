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
        return ErrorStrings.accountDisabled;
      case 'user-not-found':
        return ErrorStrings.userNotFound;
      case 'wrong-password':
        return ErrorStrings.wrongPassword;
      case 'email-already-in-use':
        return ErrorStrings.emailInUse;
      case 'operation-not-allowed':
        return ErrorStrings.operationNotAllowed;
      case 'weak-password':
        return ErrorStrings.weakPassword;
      case 'too-many-requests':
        return ErrorStrings.passwordResetTooManyRequests;
      case 'network-request-failed':
        return ErrorStrings.networkError;
      case 'aborted-by-user':
      case 'cancelled-popup-request':
      case 'popup-closed-by-user':
      case 'user-cancelled':
        return ErrorStrings.processCanceledByUser;
      case 'requires-recent-login':
        return ErrorStrings.requiresRecentLogin;
      case 'invalid-credential':
      case 'invalid-verification-code':
      case 'invalid-verification-id':
        return ErrorStrings.invalidCredential;
      case 'account-exists-with-different-credential':
        return ErrorStrings.accountExistsWithDifferentCredential;
      default:
        return "${ErrorStrings.unexpectedError} (${error.code})";
    }
  }
}
