import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';

class MyMockGoogleSignIn extends MockGoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signInSilently(
      {bool suppressErrors = true, bool reAuthenticate = false}) {
    return Future(() => MockGoogleSignInAccount());
  }
}
