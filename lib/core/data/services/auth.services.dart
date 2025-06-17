// ignore_for_file: depend_on_referenced_packages

import 'package:logger/logger.dart';

import 'package:firebase_auth/firebase_auth.dart';

class Authservices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger logger = Logger();

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
    } on FirebaseAuthException catch (e, stack) {
      logger.e('Error saving token', error: e, stackTrace: stack);

      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
