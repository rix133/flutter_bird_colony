import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/design/homepageButton.dart';
import 'package:kakrarahu/screens/homepage.dart';
import 'package:kakrarahu/services/authService.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:kakrarahu/screens/settings/settings.dart';
import 'package:provider/provider.dart';

import 'mocks/mockAuthService.dart';
import 'mocks/mockSharedPreferencesService.dart';



void main() {
  final authService = MockAuthService();
  final sharedPreferencesService = MockSharedPreferencesService();
  late Widget myApp;

  setUpAll(() {
    AuthService.instance = authService;
    FirebaseFirestore firestore = FakeFirebaseFirestore();
    myApp = ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
          initialRoute: '/',
          routes: {
            '/': (context) => MyHomePage(title: "Kakrarahu nests"),
            '/settings': (context) => SettingsPage(firestore: firestore),
          }
      ),
    );
  });

  testWidgets('MyHomePage shows home page when user is signed in', (WidgetTester tester) async {
    await tester.pumpWidget(myApp);

    await tester.pumpAndSettle();

    expect(find.text('Kakrarahu nests'), findsOneWidget);
  });

  testWidgets('Settings button is found when user is signed in', (WidgetTester tester) async {
    await tester.pumpWidget(myApp);

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('Correct number of HomePageButton widgets are present when user is signed in', (WidgetTester tester) async {
    await tester.pumpWidget(myApp);

    await tester.pumpAndSettle();

    expect(find.byType(HomePageButton), findsNWidgets(5));
  });

  testWidgets('User is redirected to settings page when not signed in', (WidgetTester tester) async {
    authService.isLoggedIn = false;

    await tester.pumpWidget(myApp);

    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });

}

