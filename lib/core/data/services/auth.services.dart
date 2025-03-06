// ignore_for_file: depend_on_referenced_packages

import 'package:firebase_auth/firebase_auth.dart';

class Authservices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
<<<<<<< HEAD
      //print("Error en el registro: ${e.code} - ${e.message}");
=======
      print("Error en el registro: ${e.code} - ${e.message}");
>>>>>>> d251a602acd46738823f2be3fca9c2d66ce3e325
      rethrow; // Lanza la excepción para que pueda ser capturada en LoginScreen
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
<<<<<<< HEAD
      //print("Error en login: ${e.code} - ${e.message}");
=======
      print("Error en login: ${e.code} - ${e.message}");
>>>>>>> d251a602acd46738823f2be3fca9c2d66ce3e325
      rethrow; // Lanza la excepción para que pueda ser capturada en LoginScreen
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
