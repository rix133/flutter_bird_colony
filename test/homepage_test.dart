import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/homepage.dart';
import 'package:kakrarahu/services/authService.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

class MockAuthService extends Mock implements AuthService {
  @override
  Future<bool> isUserSignedIn() => Future.value(true);
}
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {
  @override
  bool get isLoggedIn => true;
}

void main() {
  final authService = MockAuthService();
  final sharedPreferencesService = MockSharedPreferencesService();
  late Widget myApp;

  setUpAll(() {
    AuthService.instance = authService;
    myApp = ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
        home: MyHomePage(),
      ),
    );
  });

  testWidgets('MyHomePage shows home page when user is signed in', (WidgetTester tester) async {
    await tester.pumpWidget(myApp);

    await tester.pumpAndSettle();

    expect(find.text('Kakrarahu nests'), findsOneWidget);
  });
}

