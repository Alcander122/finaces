import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finances/core/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registra un nuevo usuario con nombre, correo electrónico y contraseña
  Future<UserModel> registerUser({
    required String name,
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      // Crear usuario en Firebase Authentication
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verificar que el usuario fue creado correctamente
      final User? user = userCredential.user;
      if (user == null) {
        throw Exception("No se pudo completar el registro del usuario.");
      }

      // Crear documento del usuario en Firestore
      final userDoc = _firestore.collection('users').doc(user.uid);
      await userDoc.set({
        'uid': user.uid,
        'name': name,
        'displayName': displayName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Actualizar displayName del usuario
      await user.updateDisplayName(name);

      // Devolver el modelo de usuario completo
      return UserModel(
        uid: user.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e, stackTrace) {
      print("❌ Error en registerUser: $e");
      print("🔍 StackTrace: $stackTrace");
      rethrow;
    }
  }

  /// Actualiza la información del perfil de usuario
  Future<void> updateProfile({
    required String userId,
    required String newName,
  }) async {
    try {
      // Actualizar información en Firestore
      await _firestore.collection('users').doc(userId).update({
        'name': newName,
      });

      // Actualizar displayName en Auth
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(newName);
      }
    } catch (e, stackTrace) {
      print("❌ Error al actualizar perfil: $e");
      print("🔍 StackTrace: $stackTrace");
      rethrow;
    }
  }

  /// Obtiene la información del usuario actual
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      return UserModel.fromMap(userDoc.data()!);
    } catch (e, stackTrace) {
      print("❌ Error al obtener usuario actual: $e");
      print("🔍 StackTrace: $stackTrace");
      return null;
    }
  }

  /// Elimina la cuenta del usuario actual
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("No hay usuario autenticado.");
      }

      // Eliminar documento de Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Eliminar usuario de Auth
      await user.delete();
    } catch (e, stackTrace) {
      print("❌ Error al eliminar cuenta: $e");
      print("🔍 StackTrace: $stackTrace");
      rethrow;
    }
  }

  /// Verifica si un correo electrónico está disponible para registro
  Future<bool> isEmailAvailable(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isEmpty;
    } catch (e, stackTrace) {
      print("❌ Error al verificar disponibilidad de correo: $e");
      print("🔍 StackTrace: $stackTrace");
      rethrow;
    }
  }
}
