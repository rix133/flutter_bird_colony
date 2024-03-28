import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/homepageButton.dart';
import 'package:flutter_bird_colony/screens/homepage.dart';
import 'package:flutter_bird_colony/screens/settings/settings.dart';
import 'package:flutter_bird_colony/services/authService.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_test/flutter_test.dart';
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
        '/': (context) => MyHomePage(title: "Bird Colony nests"),
        '/settings': (context) => SettingsPage(firestore: firestore),
          }
      ),
    );
  });

  testWidgets('MyHomePage shows home page when user is signed in', (WidgetTester tester) async {
    await tester.pumpWidget(myApp);

    await tester.pumpAndSettle();

    expect(find.text('Bird Colony nests'), findsOneWidget);
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

