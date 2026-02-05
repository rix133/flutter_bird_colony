import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_bird_colony/services/authService.dart';
import 'package:mockito/mockito.dart';

import 'myMockGoogleSignIn.dart';

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
    return MyMockGoogleSignIn();
  }

  @override
  Future<void> signOut() {
    _isLoggedIn = false;
    return Future.value();
  }

  @override
  Future<void> googleSignOut() {
    return Future.value();
  }

  @override
  Future<void> ensureGoogleInitialized(
      {String? clientId, String? serverClientId}) {
    return Future.value();
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

  Future<void> sendPasswordResetEmail(String email) {
    return Future.value();
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
