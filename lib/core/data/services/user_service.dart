import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finances/core/data/models/user_model.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registra un nuevo usuario con email y contraseña, y guarda sus datos en Firestore
  Future<UserModel> registerUser({
    required String name,
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      // Crea el usuario en FirebaseAuth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) throw Exception("No se pudo completar el registro.");

      // Guarda los datos adicionales del usuario en Firestore
      final userDoc = _firestore.collection('users').doc(user.uid);
      await userDoc.set({
        'uid': user.uid,
        'name': name,
        'displayName': displayName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'acceptedTerms': true,
      });

      // Actualiza el nombre para mostrar en FirebaseAuth
      await user.updateDisplayName(name);

      return UserModel(
        uid: user.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza el nombre del usuario en Firestore y FirebaseAuth
  Future<void> updateProfile({
    required String userId,
    required String newName,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'name': newName,
      });

      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(newName);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene los datos del usuario actual desde Firestore
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      return UserModel.fromMap(userDoc.data()!);
    } catch (e) {
      return null;
    }
  }

  /// Elimina el documento de usuario en Firestore y la cuenta de FirebaseAuth
  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("No hay usuario autenticado.");

      // Reautenticar al usuario (requerido para operaciones sensibles)
      if (user.providerData
          .any((provider) => provider.providerId == 'password')) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }

      // Eliminar datos primero en Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Luego eliminar cuenta de Firebase Auth
      await user.delete(); // Requiere autenticación reciente [[4]]
    } catch (e) {
      rethrow;
    }
  }

  /// Verifica si un correo ya está registrado en FirebaseAuth
  Future<bool> isEmailAvailable(String email) async {
    try {
      // ignore: deprecated_member_use
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isEmpty;
    } catch (e) {
      rethrow;
    }
  }

  // ========================================================
  // MÉTODOS PARA USUARIOS GOOGLE
  // ========================================================

  /// Verifica si el documento del usuario existe en Firestore
  Future<bool> userExists(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.exists;
  }

  /// Guarda el usuario de Google manualmente en Firestore después del registro
  Future<void> saveGoogleUser(User user, String name) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'displayName': user.displayName ?? name,
      'email': user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'acceptedTerms': true,
    });

    // Actualiza el displayName en FirebaseAuth
    await user.updateDisplayName(name);
  }

  /// Registra manualmente un usuario autenticado con Google en Firestore.
  /// Este método **solo se debe llamar si ya se autenticó con Google**
  /// y se confirmó que aún no existe su documento en Firestore.
  Future<void> registerGoogleUser({
    required String uid,
    required String name,
    required String email,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);

    final doc = await userRef.get();
    if (!doc.exists) {
      await userRef.set({
        'uid': uid,
        'name': name,
        'email': email,
        'acceptedTerms': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
