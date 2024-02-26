import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/homepage.dart';
import 'package:kakrarahu/services/authService.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:kakrarahu/settings.dart';
import 'package:provider/provider.dart';

import 'mocks/mockAuthService.dart';
import 'mocks/mockSharedPreferencesService.dart';


void main() {
  final authService = MockAuthService();
  final sharedPreferencesService = MockSharedPreferencesService();
  late Widget myApp;

  setUpAll(() {
    AuthService.instance = authService;
    myApp = ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
          initialRoute: '/',
          routes: {
            '/': (context) => MyHomePage(title: "Nest app"),
            '/settings': (context) => SettingsPage(),
          }
      ),
    );
  });

  testWidgets('User is redirected to settings page when not signed in', (WidgetTester tester) async {
    authService.isLoggedIn = false;
    await tester.pumpWidget(myApp);

    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });

    testWidgets('Login buttons are displayed when user is not logged in', (WidgetTester tester) async {
      authService.isLoggedIn = false;
      await tester.pumpWidget(myApp);

      await tester.pumpAndSettle();

      // Check if the login buttons are displayed
      expect(find.text('Login with Google'), findsOneWidget);
      expect(find.text('Login with email'), findsOneWidget);

      // Check if other buttons are not displayed
      expect(find.text('Logout'), findsNothing);
      expect(find.text('Edit default settings'), findsNothing);
      expect(find.text('Manage species'), findsNothing);
    });

  }

