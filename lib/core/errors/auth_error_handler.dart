import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorHandler {
  static String getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'invalid-credential':
        return 'Credenciales inválidas o han expirado';
      default:
        return 'Ocurrió un error inesperado. Por favor, intenta de nuevo.';
    }
  }

  static String getGenericErrorMessage() {
    return 'Ocurrió un error inesperado. Por favor, intenta de nuevo.';
  }
}
