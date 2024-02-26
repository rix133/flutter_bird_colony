import 'package:kakrarahu/services/authService.dart';
import 'package:mockito/mockito.dart';

class MockAuthService extends Mock implements AuthService {
  bool _isLoggedIn = true;
  set isLoggedIn(bool value) => _isLoggedIn = value;
  @override
  Future<bool> isUserSignedIn() => Future.value(_isLoggedIn);
}