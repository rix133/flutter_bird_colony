import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth;
  static bool _googleInitialized = false;

  AuthService(this._auth);

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<bool> isUserSignedIn() async {
    return _auth.currentUser != null;
  }

  String? userName() => _auth.currentUser?.displayName;

  String? userEmail() => _auth.currentUser?.email;

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithCredential(OAuthCredential credential) {
    return _auth.signInWithCredential(credential);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _auth.signOut();

  GoogleSignIn getGoogleSignIn() => GoogleSignIn.instance;

  Future<void> ensureGoogleInitialized({
    String? clientId,
    String? serverClientId,
  }) async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
    _googleInitialized = true;
  }

  Future<void> googleSignOut() => GoogleSignIn.instance.signOut();
}
