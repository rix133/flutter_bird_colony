import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:kakrarahu/services/authService.dart';
import 'package:mockito/mockito.dart';

class MockAuthService extends Mock implements AuthService {
  late MockUser user;
  FirebaseAuth mockFirebaseAuth = MockFirebaseAuth();
  bool _isLoggedIn = true;
  set isLoggedIn(bool value) => _isLoggedIn = value;

  @override
  Future<bool> isUserSignedIn() => Future.value(_isLoggedIn);

  @override
  String? userName() {
    return "Test User";
  }

  @override
  getGoogleSignIn() {
    return MockGoogleSignIn();
  }

  @override
  Future<void> signOut() {
    _isLoggedIn = false;
    return Future.value();
  }

  @override
  Future<void> googleSignOut() {
    return Future.value(null);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword(
      {String? email, String? password}) {
    if (email == "a" || email == null) {
      return Future.error(FirebaseAuthException(code: 'invalid-email'));
    }
    if ((password?.length ?? 0) < 6) {
      return Future.error(FirebaseAuthException(code: 'weak-password'));
    }

    user = MockUser(
      isAnonymous: false,
      uid: 'someuid',
      email: email,
      displayName: 'test',
    );
    mockFirebaseAuth = MockFirebaseAuth(mockUser: user);
    _isLoggedIn = true;
    return mockFirebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password!);
  }

  Future<UserCredential> signInWithEmailAndPassword(
      {String? email, String? password}) {
    if (email == "admin@example.com" || email == "a" || email == null) {
      return Future.error(FirebaseAuthException(code: 'user-not-found'));
    }

    user = MockUser(
      isAnonymous: false,
      uid: 'someuid',
      email: email,
      displayName: 'test',
    );
    if (password == "password123") {
      mockFirebaseAuth = MockFirebaseAuth(mockUser: user);
      _isLoggedIn = true;
      return mockFirebaseAuth.signInWithEmailAndPassword(
          email: email, password: password!);
    } else if (password == "password312") {
      return Future.error(FirebaseAuthException(code: 'wrong-password'));
    } else {
      return mockFirebaseAuth.signInWithEmailAndPassword(
          email: email, password: password!);
    }
  }
}