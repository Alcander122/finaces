import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finances/core/data/models/user_model.dart';

enum AuthProviderType {
  email,
  google,
  facebook,
  unknown,
}

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

  /// Detecta el tipo de proveedor de autenticación del usuario actual
  AuthProviderType getAuthProviderType() {
    final user = _auth.currentUser;
    if (user == null) return AuthProviderType.unknown;

    for (final provider in user.providerData) {
      if (provider.providerId == 'password') return AuthProviderType.email;
      if (provider.providerId == 'google.com') return AuthProviderType.google;
      if (provider.providerId == 'facebook.com') {
        return AuthProviderType.facebook;
      }
    }

    return AuthProviderType.unknown;
  }

  /// Elimina el documento de usuario en Firestore y la cuenta de FirebaseAuth
  /// [password] solo es requerido para usuarios con email/contraseña.
  Future<void> deleteAccount({String? password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("No hay usuario autenticado.");

      final authProvider = getAuthProviderType();

      if (authProvider == AuthProviderType.email) {
        if (password == null || password.isEmpty) {
          throw Exception(
              "La contraseña es requerida para eliminar la cuenta.");
        }

        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      } else if (authProvider == AuthProviderType.google ||
          authProvider == AuthProviderType.facebook) {
        await user.getIdToken(true);
      }

      // 1. Eliminar todas las subcolecciones y datos de Firestore del usuario
      await _deleteAllUserData(user.uid);

      // 2. Eliminar la cuenta de Firebase Auth
      await user.delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Elimina recursivamente todas las subcolecciones, documentos anidados
  /// y el documento raíz del usuario en Firestore.
  Future<void> _deleteAllUserData(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    final subcollections = [
      'ahorro',
      'bancos',
      'egreso',
      'ingresos',
      'pagos',
      'portafolios',
    ];

    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (final subcol in subcollections) {
      final snapshot = await userRef.collection(subcol).get();
      for (final doc in snapshot.docs) {
        // Si es portafolios, eliminar primero la subcolección anidada investments
        if (subcol == 'portafolios') {
          final investmentsSnap =
              await doc.reference.collection('investments').get();
          for (final invDoc in investmentsSnap.docs) {
            batch.delete(invDoc.reference);
            count++;
            if (count >= 400) {
              await batch.commit();
              batch = _firestore.batch();
              count = 0;
            }
          }
        }

        batch.delete(doc.reference);
        count++;
        if (count >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          count = 0;
        }
      }
    }

    // Finalmente borramos el documento raíz del usuario
    batch.delete(userRef);
    await batch.commit();
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
    return userDoc.exists && userDoc.data() != null && userDoc.data()!.isNotEmpty;
  }

  /// Sincroniza o actualiza la información del usuario de Google en Firestore.
  /// Si el documento no existe o le faltan campos esenciales (como nombre, correo, etc.),
  /// los agrega usando `merge: true` sin sobreescribir ni borrar otros datos existentes (subcolecciones, tutorialSeen, etc.).
  Future<void> syncGoogleUser({required User user}) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final doc = await userRef.get();

      final String name = (user.displayName != null && user.displayName!.trim().isNotEmpty)
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? 'Usuario');
      final String displayName = name;
      final String email = user.email ?? '';

      if (!doc.exists || doc.data() == null || doc.data()!.isEmpty) {
        // El documento no existe o es un contenedor vacío
        await userRef.set({
          'uid': user.uid,
          'name': name,
          'displayName': displayName,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'acceptedTerms': true,
          'tutorialSeen': false,
        }, SetOptions(merge: true));
      } else {
        // El documento existe pero verificamos si faltan campos
        final data = doc.data()!;
        final Map<String, dynamic> updates = {};

        if (data['uid'] == null || (data['uid'] is String && (data['uid'] as String).isEmpty)) {
          updates['uid'] = user.uid;
        }
        if (data['name'] == null || (data['name'] is String && (data['name'] as String).isEmpty)) {
          updates['name'] = name;
        }
        if (data['displayName'] == null || (data['displayName'] is String && (data['displayName'] as String).isEmpty)) {
          updates['displayName'] = displayName;
        }
        if (data['email'] == null || (data['email'] is String && (data['email'] as String).isEmpty)) {
          updates['email'] = email;
        }
        if (data['createdAt'] == null) {
          updates['createdAt'] = FieldValue.serverTimestamp();
        }
        if (data['acceptedTerms'] == null) {
          updates['acceptedTerms'] = true;
        }
        if (data['tutorialSeen'] == null) {
          updates['tutorialSeen'] = false;
        }

        if (updates.isNotEmpty) {
          await userRef.set(updates, SetOptions(merge: true));
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Guarda el usuario de Google manualmente en Firestore después del registro
  Future<void> saveGoogleUser(User user, String name) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    await userRef.set({
      'uid': user.uid,
      'name': name,
      'displayName': user.displayName ?? name,
      'email': user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'acceptedTerms': true,
      'tutorialSeen': false,
    }, SetOptions(merge: true));

    // Actualiza el displayName en FirebaseAuth
    await user.updateDisplayName(name);
  }

  /// Registra manualmente un usuario autenticado con Google en Firestore.
  Future<void> registerGoogleUser({
    required String uid,
    required String name,
    required String email,
    String? displayName,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final actualName = name.trim().isNotEmpty ? name.trim() : (email.split('@').first);
    final actualDisplayName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : actualName;

    final doc = await userRef.get();
    if (!doc.exists || doc.data() == null || doc.data()!.isEmpty) {
      await userRef.set({
        'uid': uid,
        'name': actualName,
        'displayName': actualDisplayName,
        'email': email,
        'acceptedTerms': true,
        'tutorialSeen': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      final data = doc.data()!;
      final Map<String, dynamic> updates = {};
      if (data['uid'] == null || (data['uid'] is String && (data['uid'] as String).isEmpty)) {
        updates['uid'] = uid;
      }
      if (data['name'] == null || (data['name'] is String && (data['name'] as String).isEmpty)) {
        updates['name'] = actualName;
      }
      if (data['displayName'] == null || (data['displayName'] is String && (data['displayName'] as String).isEmpty)) {
        updates['displayName'] = actualDisplayName;
      }
      if (data['email'] == null || (data['email'] is String && (data['email'] as String).isEmpty)) {
        updates['email'] = email;
      }
      if (data['createdAt'] == null) {
        updates['createdAt'] = FieldValue.serverTimestamp();
      }
      if (data['acceptedTerms'] == null) {
        updates['acceptedTerms'] = true;
      }
      if (data['tutorialSeen'] == null) {
        updates['tutorialSeen'] = false;
      }

      if (updates.isNotEmpty) {
        await userRef.set(updates, SetOptions(merge: true));
      }
    }
  }
}
