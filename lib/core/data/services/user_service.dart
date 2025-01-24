import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Asegurar que `userCredential` contiene un usuario válido
      final User? user = userCredential.user;
      if (user == null) {
        throw Exception("No se pudo obtener el usuario después del registro.");
      }

      print("✅ Usuario registrado con UID: ${user.uid}");

      // Agregar usuario a Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Intentar actualizar el display name (puede fallar)
      try {
        await user.updateDisplayName(name);
        print("✅ Nombre de usuario actualizado: $name");
      } catch (e) {
        print("⚠️ No se pudo actualizar el nombre de usuario: $e");
      }
    } catch (e, stackTrace) {
      print("❌ Error en registerUser: $e");
      print("🔍 StackTrace: $stackTrace");
      throw Exception("Error al registrar usuario: $e");
    }
  }
}
