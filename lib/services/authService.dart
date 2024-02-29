import 'package:firebase_auth/firebase_auth.dart';


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



}