import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  Future<bool> isUserSignedIn() async {
    // Check if user is signed in with email
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      return true;
    }

    return false;
  }

  String? userName() {
    return _auth.currentUser?.displayName;
  }

  Future<UserCredential> createUserWithEmailAndPassword(
      {String? email, String? password}) async {
    if (email == null || password == null)
      return throw (FirebaseAuthException(code: 'invalid-email'));
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithEmailAndPassword(
      {String? email, String? password}) async {
    if (email == null || password == null)
      return throw (FirebaseAuthException(code: 'invalid-email'));
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithCredential(
      OAuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return (_auth.sendPasswordResetEmail(email: email));
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  GoogleSignIn getGoogleSignIn() {
    return GoogleSignIn();
  }

  Future<void> googleSignOut() {
    return (getGoogleSignIn().signOut());
  }
}