import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:flutter/foundation.dart';

/// Traduce errores de Base de Datos y Red a mensajes amigables UX
class DbErrorHandler {
  static String handle(dynamic error) {
    debugPrint("💾 DB Error Catch: $error");

    // 1. Manejo de errores específicos de Firestore
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return ErrorStrings.permissionDenied;
        case 'unavailable':
        case 'network-request-failed':
          return ErrorStrings.networkError;
        case 'not-found':
          return ErrorStrings.dataNotFound;
        case 'cancelled':
        case 'aborted':
          return ErrorStrings.unexpectedError;
        case 'deadline-exceeded':
          return ErrorStrings.networkError; // Timeout de Firestore
        default:
          return kDebugMode
              ? "${ErrorStrings.unexpectedError} (${error.code})"
              : ErrorStrings.unexpectedError;
      }
    }

    // 2. Errores genéricos de Dart (Conversiones, Casts, etc.)
    if (error is FormatException || error is TypeError) {
      debugPrint("⚠️ Data Parsing Error: ${error.toString()}");
      return ErrorStrings.unexpectedError;
    }

    // 3. Cualquier otra excepción no controlada
    return ErrorStrings.unexpectedError;
  }
}
