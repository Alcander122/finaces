import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Inicia sesión con Facebook y autentica con Firebase
  Future<UserCredential> signInWithFacebook() async {
    try {
      // Si es web, se hace con login web
      if (kIsWeb) {
        final LoginResult loginResult = await FacebookAuth.instance.login();

        if (loginResult.status != LoginStatus.success) {
          throw FirebaseAuthException(
            code: 'ERROR_FACEBOOK_LOGIN_FAILED',
            message: loginResult.message,
          );
        }

        final OAuthCredential facebookAuthCredential =
            FacebookAuthProvider.credential(
          loginResult.accessToken!.tokenString,
        );

        return await _firebaseAuth.signInWithCredential(facebookAuthCredential);
      } else {
        // Móvil
        final LoginResult result = await FacebookAuth.instance.login(
          permissions: ['email', 'public_profile'],
        );

        if (result.status == LoginStatus.success) {
          final AccessToken accessToken = result.accessToken!;
          final OAuthCredential credential =
              FacebookAuthProvider.credential(accessToken.tokenString);
          return await _firebaseAuth.signInWithCredential(credential);
        } else {
          throw FirebaseAuthException(
            code: 'ERROR_FACEBOOK_LOGIN_FAILED',
            message: result.message,
          );
        }
      }
    } catch (e) {
      throw FirebaseAuthException(
        code: 'ERROR_FACEBOOK_AUTH',
        message: e.toString(),
      );
    }
  }

  /// Cierra sesión de Facebook y Firebase
  Future<void> signOutFacebook() async {
    await FacebookAuth.instance.logOut();
    await _firebaseAuth.signOut();
  }
}
