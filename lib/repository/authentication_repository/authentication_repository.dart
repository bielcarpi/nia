import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nia_flutter/utils/validator/validator.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User get user => _auth.currentUser!;

  bool buttonClicked = false;

  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  Future<bool> signInWithGoogle(BuildContext context) async {
    if (buttonClicked) return false;
    buttonClicked = true;

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        buttonClicked = false;
        return false;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
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

  Future<bool> signInWithFacebook(BuildContext context) async {
    /*
    if (buttonClicked) return false;
    buttonClicked = true;

    try {
      final LoginResult result = await FacebookAuth.instance.login();
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

  Future<bool> signInWithApple(BuildContext context) async {
    if (buttonClicked) return false;
    buttonClicked = true;

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
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
     */
    return false;
  }

  Future<bool> login(String email, String password) async {
    if (buttonClicked) return false;
    buttonClicked = true;

    if (!Validator.email(email) || !Validator.password(password)) {
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

  Future<bool> register(String email, String password) async {
    if (buttonClicked) return false;
    buttonClicked = true;

    if (!Validator.email(email) || !Validator.password(password)) {
      buttonClicked = false;
      return false;
    }

    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      buttonClicked = false;
      return true;
    } catch (e) {
      buttonClicked = false;
      return false;
    }
  }
}
