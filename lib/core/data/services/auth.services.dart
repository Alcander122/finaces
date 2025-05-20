// ignore_for_file: depend_on_referenced_packages

import 'package:firebase_auth/firebase_auth.dart';

class Authservices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException {
      //print("Error en el registro: ${e.code} - ${e.message}");
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException {
      //print("Error en login: ${e.code} - ${e.message}");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
