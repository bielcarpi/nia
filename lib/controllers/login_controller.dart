import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nia_flutter/utils/validator/validator.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginController {
  final FirebaseAuth _auth = FirebaseAuth.instance;  //instància de FirebaseAuth per manejar les funcions d'autenticació.
  bool buttonClicked = false;                        //instància per evitar molts clics.


  // Funció per iniciar sessió amb Google
  Future<bool> signInWithGoogle(BuildContext context) async {
    if (buttonClicked) return false;
    buttonClicked = true;

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();    //dependencia de (google_sign_in)
      if (googleUser == null) {
        buttonClicked = false;
        return false;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      buttonClicked = false;
      return true;
    } catch (e) {
      buttonClicked = false;
      return false;
    }
  }

  // Funció per iniciar sessió amb Facebook
  Future<bool> signInWithFacebook(BuildContext context) async {
    if (buttonClicked) return false;
    buttonClicked = true;

    try {
      final LoginResult result = await FacebookAuth.instance.login();           //dependencia de (flutter_facebook_auth)
      if (result.status == LoginStatus.success) {
        final AuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.token);
        await _auth.signInWithCredential(credential);
        buttonClicked = false;
        return true;
      } else {
        buttonClicked = false;
        return false;
      }
    } catch (e) {
      buttonClicked = false;
      return false;
    }
  }

  // Funció per iniciar sessió amb Apple
  Future<bool> signInWithApple(BuildContext context) async {
    if (buttonClicked) return false;
    buttonClicked = true;

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(                   //dependencia de (ign_in_with_apple)
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      await _auth.signInWithCredential(oauthCredential);
      buttonClicked = false;
      return true;
    } catch (e) {
      buttonClicked = false;
      return false;
    }
  }

  // Funció per iniciar sessió amb el correo electrónic i una contrasenya
  Future<bool> login(String email, String password) async {
    if (buttonClicked) return false;
    buttonClicked = true;

    if (!Validator.email(email) || !Validator.password(password)) {                       //paquet de ('package:nia_flutter/utils/validator/validator.dart')
      buttonClicked = false;
      return false;
    }

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      buttonClicked = false;
      return true;
    } catch (e) {
      buttonClicked = false;
      return false;
    }
  }

  // Funció per registrar-se amb un correo electrónic i una contrasenya
  Future<bool> register(String email, String password) async {
    if (buttonClicked) return false;
    buttonClicked = true;

    if (!Validator.email(email) || !Validator.password(password)) {
      buttonClicked = false;
      return false;
    }

    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      buttonClicked = false;
      return true;
    } catch (e) {
      buttonClicked = false;
      return false;
    }
  }
}
