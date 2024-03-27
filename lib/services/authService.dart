import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {

  static AuthService instance = AuthService();



  Future<bool> isUserSignedIn() async {
    // Check if user is signed in with email
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      return true;
    }

    return false;
  }

  String? userName() {
    return FirebaseAuth.instance.currentUser?.displayName;
  }

  Future<UserCredential> createUserWithEmailAndPassword(
      {String? email, String? password}) async {
    if (email == null || password == null)
      return throw (FirebaseAuthException(code: 'invalid-email'));
    return await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithEmailAndPassword(
      {String? email, String? password}) async {
    if (email == null || password == null)
      return throw (FirebaseAuthException(code: 'invalid-email'));
    return await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithCredential(
      OAuthCredential credential) async {
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return (FirebaseAuth.instance.sendPasswordResetEmail(email: email));
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  GoogleSignIn getGoogleSignIn() {
    return GoogleSignIn();
  }

  Future<void> googleSignOut() {
    return (getGoogleSignIn().signOut());
  }
}