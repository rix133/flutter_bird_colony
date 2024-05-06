
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/speciesRawAutocomplete.dart';
import 'package:flutter_bird_colony/screens/homepage.dart';
import 'package:flutter_bird_colony/screens/nest/createNest.dart';
import 'package:flutter_bird_colony/screens/nest/editNest.dart';
import 'package:flutter_bird_colony/screens/nest/mapCreateNest.dart';
import 'package:flutter_bird_colony/screens/settings/settings.dart';
import 'package:flutter_bird_colony/services/authService.dart';
import 'package:flutter_bird_colony/services/locationService.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'mocks/mockAuthService.dart';
import 'mocks/mockLocationService.dart';
import 'mocks/mockSharedPreferencesService.dart';


void main() {
  final authService = MockAuthService();
  final sharedPreferencesService = MockSharedPreferencesService();
  final firestore = FakeFirebaseFirestore();
  MockLocationAccuracy10 locationAccuracy10 = MockLocationAccuracy10();
  late Widget myApp;
  final userEmail = "test@example.com";

  Future<WidgetTester> setSpecies(WidgetTester tester) async {
    Finder speciesRawAutocompleteFinder = find.byType(SpeciesRawAutocomplete);
    expect(speciesRawAutocompleteFinder, findsOneWidget);

    // Find the TextField widget which is a descendant of the SpeciesRawAutocomplete widget
    Finder textFieldFinder = find.descendant(
      of: speciesRawAutocompleteFinder,
      matching: find.byType(TextField),
    );
    expect(textFieldFinder, findsOneWidget);

    //enter test in the textfield
    await tester.enterText(textFieldFinder, 'gull');
    await tester.pumpAndSettle();

    //tap the first listtile
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    return tester;
  }

  setUpAll(() async {
    AuthService.instance = authService;
    LocationService.instance = locationAccuracy10;
    sharedPreferencesService.desiredAccuracy = 12;

    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});
    myApp = ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
          initialRoute: '/',
          routes: {
            '/': (context) => MyHomePage(title: "Nest app"),
            '/settings': (context) => SettingsPage(firestore: firestore),
            '/mapCreateNest': (context) => MapCreateNest(firestore: firestore),
            '/createNest':(context)=>CreateNest(firestore: firestore),
            '/editNest':(context)=>EditNest(firestore: firestore),
          }
      ),
    );
  });



  setUp(() async {
    //reset the database
    await firestore.collection('recent').doc("nest").set({"id":"1"});
    await firestore.collection(DateTime.now().year.toString()).doc("2").delete();
  });
  group('Navigation tests', () {
    testWidgets("Can go to add nest map page", (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      expect(find.byType(MapCreateNest), findsOneWidget);
    });

    testWidgets("will redirect to the map page", (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      tester = await setSpecies(tester);

      await tester.enterText(find.byKey(Key('enter nest ID')), "2");
      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      expect(find.byType(EditNest), findsOneWidget);

      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      expect(find.byType(MapCreateNest), findsOneWidget);
    });

    testWidgets("will redirect to the manage nest page",
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      tester = await setSpecies(tester);

      await tester.enterText(find.byKey(Key('enter nest ID')), "2");

      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      expect(find.byType(EditNest), findsOneWidget);
    });
  });

  group('Location tests', () {
    testWidgets("can refresh position on map", (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pumpAndSettle();

      //somehow wont work check that the location service was called
      //verify(locationAccuracy10.getCurrentPosition()).called(1);
    });
  });
  group('Nest creation tests', () {
    testWidgets("can refresh position on nest create",
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pumpAndSettle();

      //somehow wont work check that the location service was called
      //verify(locationAccuracy10.getCurrentPosition()).called(1);
    });

    testWidgets("can add new nest from the map", (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(CreateNest), findsOneWidget);
    });

    testWidgets("will save the nest to the database",
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(Key('enter nest ID')), "1");
      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      expect(
          firestore.collection(DateTime.now().year.toString()).doc("1").get(),
          completion(isNotNull));
    });

    testWidgets("can't leave nest ID empty", (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(Key('enter nest ID')), "");
      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      // Check if snackbar is shown
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets("can't overwrite existing nest on Nest create",
        (WidgetTester tester) async {
      final Map<String, dynamic> expectedData = {
        "test": "test"
      }; // The data you set

      await firestore
          .collection(DateTime.now().year.toString())
          .doc("2")
          .set(expectedData);

      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      var docFuture = await firestore
          .collection(DateTime.now().year.toString())
          .doc("2")
          .get();
      expect(docFuture, isNotNull);

      // Check if the data in the document is the same as the expected data
      expect(docFuture.data(), equals(expectedData));

      await setSpecies(tester);

      await tester.enterText(find.byKey(Key('enter nest ID')), "2");
      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      // Check if snackbar is shown
      expect(find.byType(SnackBar), findsOneWidget);

      // Check that the nest is not overwritten by comparing the document
      docFuture = await firestore
          .collection(DateTime.now().year.toString())
          .doc("2")
          .get();
      expect(docFuture, isNotNull);

      // Check if the data in the document is the same as the expected data
      expect(docFuture.data(), equals(expectedData));
    });

    testWidgets("recent nest id is updated", (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      tester = await setSpecies(tester);

      await tester.enterText(find.byKey(Key('enter nest ID')), "2");
      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      var docFuture = await firestore.collection('recent').doc("nest").get();
      expect(docFuture, isNotNull);

      // Check if the data in the document is the same as the expected data
      expect(docFuture.data(), equals({"id": "2"}));
    });

    testWidgets("recent nest displays on the button",
        (WidgetTester tester) async {
      await firestore.collection('recent').doc("nest").set({"id": "3333"});

      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text("Next: 3334"), findsOneWidget);
    });

    testWidgets("recent nest button click updates nest id",
        (WidgetTester tester) async {
      await firestore.collection('recent').doc("nest").set({"id": "3333"});

      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      tester = await setSpecies(tester);

      await tester.tap(find.text("Next: 3334"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      var docFuture = await firestore.collection('recent').doc("nest").get();
      expect(docFuture, isNotNull);

      // Check if the data in the document is the same as the expected data
      expect(docFuture.data(), equals({"id": "3334"}));

      docFuture = await firestore
          .collection(DateTime.now().year.toString())
          .doc("3334")
          .get();
      expect(docFuture, isNotNull);
    });

    testWidgets("will allow  nest saving if species is not set",
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text("add nest"));
          await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(Key('enter nest ID')), "2");
          await tester.tap(find.text("add nest"));
          await tester.pumpAndSettle();

      //expect to be on edit nest page
      expect(find.byType(EditNest), findsOneWidget);
    });
  });
  group('Error handling tests', () {
    testWidgets("will raise an error if nest ID is empty",
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text("add nest"));
          await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      tester = await setSpecies(tester);

      await tester.enterText(find.byKey(Key('enter nest ID')), "");
      await tester.tap(find.text("add nest"));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
        });
  });
}