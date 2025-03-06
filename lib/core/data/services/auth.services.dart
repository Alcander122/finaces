import 'package:firebase_auth/firebase_auth.dart';

class Authservices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      print("Error en el registro: ${e.code} - ${e.message}");
      rethrow; // Lanza la excepción para que pueda ser capturada en LoginScreen
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      print("Error en login: ${e.code} - ${e.message}");
      rethrow; // Lanza la excepción para que pueda ser capturada en LoginScreen
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
