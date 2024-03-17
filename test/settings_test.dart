import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/design/speciesRawAutocomplete.dart';
import 'package:kakrarahu/models/firestore/defaultSettings.dart';
import 'package:kakrarahu/models/firestore/species.dart';
import 'package:kakrarahu/screens/homepage.dart';
import 'package:kakrarahu/screens/settings/settings.dart';
import 'package:kakrarahu/services/authService.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

import 'mocks/mockAuthService.dart';
import 'mocks/mockSharedPreferencesService.dart';


void main() {
  final authService = MockAuthService();
  final sharedPreferencesService = MockSharedPreferencesService();
  final FirebaseFirestore firestore = FakeFirebaseFirestore();
  late Widget myApp;
  final adminEmail = "admin@example.com";
  final userEmail = "test@example.com";
  group('Settings for normal user', () {
    setUpAll(() async {
    AuthService.instance = authService;
    await firestore.collection('users').doc(adminEmail).set({'isAdmin': true});
    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});
    myApp = ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
          initialRoute: '/',
          routes: {
            '/': (context) => MyHomePage(title: "Nest app"),
            '/settings': (context) => SettingsPage(firestore: firestore),
          }
      ),
    );
  });

  testWidgets('User is redirected to settings page when not signed in', (WidgetTester tester) async {
    authService.isLoggedIn = false;
    sharedPreferencesService.isAdmin = false;
    await tester.pumpWidget(myApp);

    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });

    testWidgets('Login buttons are displayed when user is not logged in', (WidgetTester tester) async {
      authService.isLoggedIn = false;
      sharedPreferencesService.isAdmin = false;
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

  testWidgets('Login with email button pressed', (WidgetTester tester) async {
    authService.isLoggedIn = false;
    sharedPreferencesService.isAdmin = false;
    await tester.pumpWidget(myApp);

    await tester.pumpAndSettle();

    // Tap the login with email button
    await tester.tap(find.text('Login with email'));
    await tester.pumpAndSettle();

    // Check if the login page is displayed
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Log out button is displayed when user is logged in', (WidgetTester tester) async {
    authService.isLoggedIn = true;
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //go to settings page
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Check if the logout button is displayed
    expect(find.text('Logout'), findsOneWidget);

    // Check if other buttons are not displayed
    expect(find.text('Login with Google'), findsNothing);
    expect(find.text('Login with email'), findsNothing);
    expect(find.text('Edit default settings'), findsNothing);
    expect(find.text('Manage species'), findsNothing);
  });


  testWidgets("login with email is triggered", (WidgetTester tester) async {
    authService.isLoggedIn = false;
    sharedPreferencesService.isAdmin = false;
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login with email'));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
  });

    testWidgets("default species RawAutocomplete is displayed",
        (WidgetTester tester) async {
      authService.isLoggedIn = true;
      sharedPreferencesService.isAdmin = false;
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //go to settings page
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.byType(SpeciesRawAutocomplete), findsOneWidget);
    });

    testWidgets("default species is changed", (WidgetTester tester) async {
      authService.isLoggedIn = true;
      sharedPreferencesService.isAdmin = false;
      expect(sharedPreferencesService.defaultSpecies, "Common Gull");
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //go to settings page
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      Finder speciesRawAutocompleteFinder = find.byType(SpeciesRawAutocomplete);
      expect(speciesRawAutocompleteFinder, findsOneWidget);

      // Find the TextField widget which is a descendant of the SpeciesRawAutocomplete widget
      Finder textFieldFinder = find.descendant(
        of: speciesRawAutocompleteFinder,
        matching: find.byType(TextField),
      );
      expect(textFieldFinder, findsOneWidget);

      //enter test in the textfield
      await tester.enterText(textFieldFinder, 'tern');
      await tester.pumpAndSettle();

      await tester.tap(find.text("Arctic tern"));
      await tester.pumpAndSettle();

      expect(sharedPreferencesService.defaultSpecies, "Arctic tern");
    });

    testWidgets("default species is reset", (WidgetTester tester) async {
      authService.isLoggedIn = true;
      sharedPreferencesService.isAdmin = false;
      sharedPreferencesService.defaultSpecies = "Arctic tern";
      expect(sharedPreferencesService.defaultSpecies, "Arctic tern");
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //go to settings page
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      Finder speciesRawAutocompleteFinder = find.byType(SpeciesRawAutocomplete);
      expect(speciesRawAutocompleteFinder, findsOneWidget);

      //save the default settings to firestore
      await firestore.collection('settings').doc("default").set(DefaultSettings(
            desiredAccuracy: 4.0,
            selectedYear: DateTime.now().year,
            autoNextBand: false,
            autoNextBandParent: false,
            defaultLocation: GeoPoint(58.766218, 23.430432),
            biasedRepeatedMeasurements: false,
            measures: [],
            markerColorGroups: [],
            defaultSpecies:
                Species(english: "Common Gull", latinCode: "", local: ""),
          ).toJson());

      // Find the TextField widget which is a descendant of the SpeciesRawAutocomplete widget
      Finder textFieldFinder = find.descendant(
        of: speciesRawAutocompleteFinder,
        matching: find.byType(TextField),
      );
      expect(textFieldFinder, findsOneWidget);

      //enter test in the textfield
      await tester.enterText(textFieldFinder, 'tern');
      await tester.pumpAndSettle();

      await tester.tap(find.text("Arctic tern"));
      await tester.pumpAndSettle();

      expect(sharedPreferencesService.defaultSpecies, "Arctic tern");

      await tester.tap(find.byIcon(Icons.recycling));
      await tester.pumpAndSettle();

      expect(sharedPreferencesService.defaultSpecies, "Common Gull");
    });
  });
  group("Settings for admin user", () {
    setUpAll(() async {
      AuthService.instance = authService;
      FirebaseFirestore firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc(adminEmail)
          .set({'isAdmin': true});
      await firestore
          .collection('users')
          .doc(userEmail)
          .set({'isAdmin': false});
      myApp = ChangeNotifierProvider<SharedPreferencesService>(
        create: (_) => sharedPreferencesService,
        child: MaterialApp(initialRoute: '/', routes: {
          '/': (context) => MyHomePage(title: "Nest app"),
          '/settings': (context) => SettingsPage(firestore: firestore),
        }),
      );
    });

    testWidgets('Admin buttons are displayed when admin is logged in',
        (WidgetTester tester) async {
      authService.isLoggedIn = true;
      sharedPreferencesService.isAdmin = true;
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //go to settings page
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Check if the admin buttons are displayed
      expect(find.text('Logout'), findsOneWidget);
      expect(find.text('Edit default settings'), findsOneWidget);
      expect(find.text('Manage species'), findsOneWidget);

      // Check if other buttons are not displayed
      expect(find.text('Login with Google'), findsNothing);
      expect(find.text('Login with email'), findsNothing);
    });

    testWidgets('Buttons are displayed when user is logged in',
        (WidgetTester tester) async {
      authService.isLoggedIn = true;
      sharedPreferencesService.isAdmin = true;
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //go to settings page
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Check if other buttons are not displayed
      expect(find.text('Logout'), findsOneWidget);
      expect(find.text('Edit default settings'), findsOneWidget);
      expect(find.text('Manage species'), findsOneWidget);
    });
  });
}
