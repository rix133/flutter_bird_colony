import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/speciesRawAutocomplete.dart';
import 'package:flutter_bird_colony/models/firestore/defaultSettings.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/screens/homepage.dart';
import 'package:flutter_bird_colony/screens/settings/editDefaultSettings.dart';
import 'package:flutter_bird_colony/screens/settings/listSpecies.dart';
import 'package:flutter_bird_colony/screens/settings/settings.dart';
import 'package:flutter_bird_colony/services/authService.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'mocks/mockAuthService.dart';
import 'mocks/mockSharedPreferencesService.dart';
import 'testApp.dart';

void main() async {
  final MockAuthService authService = MockAuthService();
  final sharedPreferencesService = MockSharedPreferencesService();
  final FirebaseFirestore firestore = FakeFirebaseFirestore();
  late TestApp myApp;
  final adminEmail = "admin@example.com";
  final userEmail = "test@example.com";

  group("Login flow messages", () {
    AuthService.instance = authService;
    setUp(() async {
      authService.isLoggedIn = false;
      sharedPreferencesService.isAdmin = false;
      await firestore
          .collection('users')
          .doc(adminEmail)
          .set({'isAdmin': true});
      await firestore
          .collection('users')
          .doc(userEmail)
          .set({'isAdmin': false});
      myApp = myApp = TestApp(
        firestore: firestore,
        sps: sharedPreferencesService,
        app: MaterialApp(initialRoute: '/settings', routes: {
          '/': (context) => MyHomePage(title: "Nest app"),
          '/settings': (context) => SettingsPage(firestore: firestore),
        }),
      );
    });

    testWidgets('Open email login dialog', (WidgetTester tester) async {
      // Initialize the app
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      // Tap the 'Login with email' button to open the dialog
      await tester.tap(find.byKey(Key('loginWithEmailButton')));
      await tester.pumpAndSettle();

      // Check if the dialog is displayed
      expect(find.text('Login with email'), findsNWidgets(2));
    });

    testWidgets('Enter email and password', (WidgetTester tester) async {
      // Initialize the app
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      // Tap the 'Login with email' button to open the dialog
      await tester.tap(find.byKey(Key('loginWithEmailButton')));
      await tester.pumpAndSettle();

      // Enter email and password
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password'), 'password123');

      // Tap the 'Login' button
      await tester.tap(find.text('Login/Register'));
      await tester.pumpAndSettle();

      // Check if the login was successful
      expect(find.byType(MyHomePage), findsOneWidget);
    });

    testWidgets('Enter email and password', (WidgetTester tester) async {
      // Initialize the app
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      // Tap the 'Login with email' button to open the dialog
      await tester.tap(find.byKey(Key('loginWithEmailButton')));
      await tester.pumpAndSettle();

      // Enter email and password
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'admin@example.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password'), 'password123');

      // Tap the 'Login' button
      await tester.tap(find.text('Login/Register'));
      await tester.pumpAndSettle();

      // Check if the login was successful
      expect(find.byType(MyHomePage), findsOneWidget);
    });

    testWidgets('Login fails with wrong password', (WidgetTester tester) async {
      // Initialize the app
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      // Tap the 'Login with email' button to open the dialog
      await tester.tap(find.byKey(Key('loginWithEmailButton')));
      await tester.pumpAndSettle();

      // Enter email and password
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password'), 'password312');

      // Tap the 'Login' button
      await tester.tap(find.text('Login/Register'));
      await tester.pumpAndSettle();

      // Check if the login was not  successful
      expect(find.byType(AlertDialog), findsNWidgets(2));
      expect(find.text('Wrong password'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNWidgets(1));
    });

    testWidgets('Login fail will show option to reset password',
        (WidgetTester tester) async {
      // Initialize the app
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      // Tap the 'Login with email' button to open the dialog
      await tester.tap(find.byKey(Key('loginWithEmailButton')));
      await tester.pumpAndSettle();

      // Enter email and password
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password'), 'password312');

      // Tap the 'Login' button
      await tester.tap(find.text('Login/Register'));
      await tester.pumpAndSettle();

      // Check if the login was not  successful
      expect(find.byType(AlertDialog), findsNWidgets(2));
      expect(find.text('Wrong password'), findsOneWidget);
      expect(find.text('Reset password'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
    });

    testWidgets("login fails with invalid email", (WidgetTester tester) async {
      // Initialize the app
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      // Tap the 'Login with email' button to open the dialog
      await tester.tap(find.byKey(Key('loginWithEmailButton')));
      await tester.pumpAndSettle();

      // Enter email and password
      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'a');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'p');

      await tester.tap(find.text('Login/Register'));
      await tester.pumpAndSettle();

      // Check if the login was not  successful
      expect(find.text("Invalid email"), findsOneWidget);
      expect(find.byType(AlertDialog), findsNWidgets(2));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNWidgets(1));
    });

    testWidgets("login fails with weak password", (WidgetTester tester) async {
      // Initialize the app
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      // Tap the 'Login with email' button to open the dialog
      await tester.tap(find.byKey(Key('loginWithEmailButton')));
      await tester.pumpAndSettle();

      // Enter email and password
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'admin@example.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'p');

      await tester.tap(find.text('Login/Register'));
      await tester.pumpAndSettle();

      // Check if the login was not  successful
      expect(find.text("Weak password"), findsOneWidget);
      expect(find.byType(AlertDialog), findsNWidgets(2));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNWidgets(1));
    });

    testWidgets('Can fail login with google', (WidgetTester tester) async {
      // Initialize the app
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      // Tap the 'Login with email' button to open the dialog
      await tester.tap(find.byKey(Key('loginWithGoogleButton')));
      await tester.pumpAndSettle();

      //for(Element e in find.byType(Text).evaluate()){
      //  print((e.widget as Text).data);
      //}

      // Check if the page is not changed
      expect(find.text("Login failed, please try again."), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      //push OK
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Create new account', (WidgetTester tester) async {
      // Initialize the app
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      // Tap the 'Login with email' button to open the dialog
      await tester.tap(find.byKey(Key('loginWithEmailButton')));
      await tester.pumpAndSettle();

      // Enter email and password
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password'), 'password123');

      // Tap the 'Create new account' button
      await tester.tap(find.text('Login/Register'));
      await tester.pumpAndSettle();
      /*
      for(Element e in find.byType(Text).evaluate()){
        print((e.widget as Text).data);
      }
       */

      // Check if the account creation was successful
      expect(find.byType(MyHomePage), findsOneWidget);
    });

    testWidgets('Create new account on empty database',
        (WidgetTester tester) async {
      //clear all users
      await firestore.collection('users').get().then((value) {
        for (var doc in value.docs) {
          doc.reference.delete();
        }
      });

      // Initialize the app
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      // Tap the 'Login with email' button to open the dialog
      await tester.tap(find.byKey(Key('loginWithEmailButton')));
      await tester.pumpAndSettle();

      // Enter email and password
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password'), 'password123');

      // Tap the 'Create new account' button
      await tester.tap(find.text('Login/Register'));
      await tester.pumpAndSettle();
      /*
      for(Element e in find.byType(Text).evaluate()){
        print((e.widget as Text).data);
      }
       */

      // Check if the account creation was successful
      expect(find.byType(MyHomePage), findsOneWidget);
    });

    testWidgets('Create new account fails user not allowed',
        (WidgetTester tester) async {
      // Initialize the app
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      // Tap the 'Login with email' button to open the dialog
      await tester.tap(find.byKey(Key('loginWithEmailButton')));
      await tester.pumpAndSettle();

      // Enter email and password
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'newuser@example.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password'), 'password123');

      // Tap the 'Create new account' button
      await tester.tap(find.text('Login/Register'));
      await tester.pumpAndSettle();

      // Check if the account creation was successful
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Not authorized'), findsOneWidget);
    });
  });

  group('Settings for normal user', () {
    setUp(() async {
      AuthService.instance = authService;
      await firestore
          .collection('users')
          .doc(adminEmail)
          .set({'isAdmin': true});
      await firestore
          .collection('users')
          .doc(userEmail)
          .set({'isAdmin': false});
      myApp = myApp = TestApp(
        firestore: firestore,
        sps: sharedPreferencesService,
        app: MaterialApp(initialRoute: '/', routes: {
          '/': (context) => MyHomePage(title: "Nest app"),
          '/settings': (context) => SettingsPage(firestore: firestore),
        }),
      );
    });

    testWidgets('User is redirected to settings page when not signed in',
        (WidgetTester tester) async {
      authService.isLoggedIn = false;
      sharedPreferencesService.isAdmin = false;
      await tester.pumpWidget(myApp);

      await tester.pumpAndSettle();
          expect(find.text('Settings'), findsOneWidget);
        });

    testWidgets("can open colony selection when not logged in",
        (WidgetTester tester) async {
      authService.isLoggedIn = false;
      sharedPreferencesService.isAdmin = false;
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      // Check if the colony testing button is displayed
      Finder colbtn = find.text('Select another colony');
      expect(colbtn, findsOneWidget);
      await tester.tap(colbtn);
      await tester.pumpAndSettle();
      expect(find.text('Select colony'), findsOneWidget);
      //tap the  button with key selectColonyButton
      await tester.tap(find.byKey(Key('selectColonyButton')));
      await tester.pumpAndSettle();
      //expect no alertdialog
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Login buttons are displayed when user is not logged in',
        (WidgetTester tester) async {
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
      await tester.tap(find.byKey(Key('loginWithEmailButton')));
      await tester.pumpAndSettle();

      // Check if the login page is displayed
      expect(find.text('Login/Register'), findsOneWidget);
      //tap the cancel
      await tester.tap(find.text('Cancel'));
    });

    testWidgets('Log out button is displayed when user is logged in',
        (WidgetTester tester) async {
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

    testWidgets('Log out button pressed', (WidgetTester tester) async {
      authService.isLoggedIn = true;
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //go to settings page
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Tap the logout button
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Check if the login page is displayed
      expect(find.text('Login with Google'), findsOneWidget);
    });

    testWidgets("login with email is triggered", (WidgetTester tester) async {
      authService.isLoggedIn = false;
      sharedPreferencesService.isAdmin = false;
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('loginWithEmailButton')));
      await tester.pumpAndSettle();
      expect(find.text('Login/Register'), findsOneWidget);
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

    testWidgets("default map type is changed", (WidgetTester tester) async {
      authService.isLoggedIn = true;
      sharedPreferencesService.isAdmin = false;
      expect(sharedPreferencesService.mapType, MapType.satellite);

      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //go to settings page
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      //find the mapType dropdown
      Finder dropdownFinder = find.byKey(Key('mapTypeDropdown'));
      expect(dropdownFinder, findsOneWidget);

      //open the dropdown
      await tester.ensureVisible(dropdownFinder);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      //select the normal map type
      await tester.tap(find.text("normal"));
      await tester.pumpAndSettle();

      expect(sharedPreferencesService.mapType, MapType.normal);
    });

    testWidgets("default settings are changed", (WidgetTester tester) async {
      authService.isLoggedIn = true;
      sharedPreferencesService.isAdmin = false;
      expect(sharedPreferencesService.defaultSpecies, "Common Gull");
      sharedPreferencesService.speciesList =
          LocalSpeciesList.fromStringList(["Common Gull", "Arctic tern"]);

      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //go to settings page
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      //find the switchlisttiles and toogle them
      Finder switchFinder = find.byType(Switch);
      expect(switchFinder, findsNWidgets(2));
      for (int i = 0; i < 2; i++) {
        await tester.tap(switchFinder.at(i));
        await tester.pumpAndSettle();
      }

      expect(sharedPreferencesService.autoNextBand, true);
      expect(sharedPreferencesService.autoNextBandParent, true);
    });

    testWidgets("default species is changed", (WidgetTester tester) async {
      authService.isLoggedIn = true;
      sharedPreferencesService.isAdmin = false;
      expect(sharedPreferencesService.defaultSpecies, "Common Gull");
      sharedPreferencesService.speciesList =
          LocalSpeciesList.fromStringList(["Common Gull", "Arctic tern"]);

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
      sharedPreferencesService.speciesList =
          LocalSpeciesList.fromStringList(["Common Gull", "Arctic tern"]);
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
            defaultCameraBearing: 270,
            defaultCameraZoom: 16.35,
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

      Finder reset = find.byIcon(Icons.recycling);
      tester.ensureVisible(reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();

      expect(sharedPreferencesService.defaultSpecies, "Common Gull");
    });
  });

  group("Settings for admin user", () {
    FirebaseFirestore firestore = FakeFirebaseFirestore();
    setUp(() async {
      AuthService.instance = authService;
      await firestore
          .collection('users')
          .doc(adminEmail)
          .set({'isAdmin': true});
      await firestore
          .collection('users')
          .doc(userEmail)
          .set({'isAdmin': false});
      myApp = myApp = TestApp(
        firestore: firestore,
        sps: sharedPreferencesService,
        app: MaterialApp(initialRoute: '/settings', routes: {
          '/': (context) => MyHomePage(title: "Nest app"),
          '/settings': (context) => SettingsPage(firestore: firestore),
          '/listSpecies': (context) => ListSpecies(firestore: firestore),
          '/editDefaultSettings': (context) =>
              EditDefaultSettings(firestore: firestore),
        }),
      );
    });

    testWidgets("can add new user email", (WidgetTester tester) async {
      authService.isLoggedIn = true;
      sharedPreferencesService.isAdmin = true;
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //find the add user button
      Finder userBtn = find.byKey(Key('addUserButton'));
      expect(userBtn, findsOneWidget);

      //ensure the button is visible
      await tester.ensureVisible(userBtn);

      //tap the add user button
      await tester.tap(userBtn);
      await tester.pumpAndSettle();

      //find the textfield
      Finder textFieldFinder = find.byKey(Key('newUserEmailTextField'));
      expect(textFieldFinder, findsOneWidget);

      //enter text in the textfield
      await tester.enterText(textFieldFinder, 'new@mail.com');
      await tester.pumpAndSettle();

      //find the save button
      await tester.tap(find.byKey(Key('saveNewUserButton')));
      await tester.pumpAndSettle();

      expect(find.text('new@mail.com'), findsOneWidget);
      var user = await firestore.collection('users').doc('new@mail.com').get();
      expect(user.exists, true);
    });

    testWidgets('Admin buttons are displayed when admin is logged in',
        (WidgetTester tester) async {
      authService.isLoggedIn = true;
      sharedPreferencesService.isAdmin = true;
      await tester.pumpWidget(myApp);
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

      // Check if other buttons are not displayed
      expect(find.text('Logout'), findsOneWidget);
      expect(find.text('Edit default settings'), findsOneWidget);
      expect(find.text('Manage species'), findsOneWidget);
    });

    testWidgets('Edit default settings button pressed',
        (WidgetTester tester) async {
      authService.isLoggedIn = true;
      sharedPreferencesService.isAdmin = true;
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //ensure that button is visible
      final btn = find.text('Edit default settings');
      expect(btn, findsOneWidget);

      //ensure visible
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      // Check if the edit default settings page is displayed
      expect(find.byType(EditDefaultSettings), findsOneWidget);
    });

    testWidgets('Manage species button pressed', (WidgetTester tester) async {
      authService.isLoggedIn = true;
      sharedPreferencesService.isAdmin = true;
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      final btn = find.text('Manage species');
      expect(btn, findsOneWidget);

      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      // Check if the manage species page is displayed
      expect(find.byType(ListSpecies), findsOneWidget);
    });

    testWidgets('Logout button pressed', (WidgetTester tester) async {
      authService.isLoggedIn = true;
      sharedPreferencesService.isAdmin = true;
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      // Tap the logout button
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Check if the login page is displayed
      expect(find.text('Login with email'), findsOneWidget);
    });
  });
}
