import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/design/speciesRawAutocomplete.dart';
import 'package:kakrarahu/models/eggStatus.dart';
import 'package:kakrarahu/models/firestore/bird.dart';
import 'package:kakrarahu/models/firestore/egg.dart';
import 'package:kakrarahu/models/firestore/experiment.dart';
import 'package:kakrarahu/models/firestore/nest.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/screens/bird/editBird.dart';
import 'package:kakrarahu/screens/bird/listBirds.dart';
import 'package:kakrarahu/screens/homepage.dart';
import 'package:kakrarahu/services/authService.dart';
import 'package:kakrarahu/services/locationService.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
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
  final Nest nest = Nest(
    id: "1",
    coordinates: GeoPoint(0, 0),
    accuracy: "3.22m",
    last_modified: DateTime.now(),
    discover_date: DateTime.now(),
    responsible: "Admin",
    species: "test",
    measures: [Measure.note()],
  );
  final Egg egg = Egg(
      id: "1 egg 1",
      discover_date: DateTime.now().subtract(Duration(days: 2)),
      responsible: "Admin",
      ring: null,
      last_modified: DateTime.now().subtract(Duration(days: 1)),
      status: EggStatus('intact'),
      measures: [Measure.note()]);
  final Experiment experiment = Experiment(
    id: "1",
    name: "New Experiment",
    description: "Test experiment",
    last_modified: DateTime.now(),
    created: DateTime.now(),
    year: DateTime
        .now()
        .year,
    responsible: "Admin",
  );

  final parent = Bird(
      ringed_date: DateTime(2022, 6, 1),
      band: 'AA1234',
      ringed_as_chick: true,
      measures: [Measure.note()],
      nest: "234",
      //2022 was the nest
      nest_year: 2022,
      responsible: 'Admin',
      last_modified: DateTime(2022, 6, 1),
      species: 'Common gull');

  final chick = Bird(
      ringed_date: DateTime.now().subtract(Duration(days: 3)),
      band: 'AA1235',
      ringed_as_chick: true,
      measures: [Measure.note()],
      nest: "1",
      //3 years ago this was the nest
      nest_year: DateTime.now().year,
      responsible: 'Admin',
      last_modified: DateTime.now().subtract(Duration(days: 3)),
      species: 'Common gull');

  final tern = Bird(
      ringed_date: DateTime.now().subtract(Duration(days: 3)),
      band: 'UU1235',
      ringed_as_chick: true,
      measures: [Measure.note()],
      nest: "123",
      //3 years ago this was the nest
      nest_year: DateTime.now().year,
      responsible: 'Admin',
      last_modified: DateTime.now().subtract(Duration(days: 3)),
      species: 'Common tern');

  setUpAll(() async {
    AuthService.instance = authService;
    LocationService.instance = locationAccuracy10;

    await firestore.collection('recent').doc("nest").set({"id": "1"});
    await firestore.collection(DateTime
        .now()
        .year
        .toString()).doc(nest.id).set(nest.toJson());
    await firestore.collection("Birds").doc(parent.band).set(parent.toJson());
    await firestore.collection("Birds").doc(chick.band).set(chick.toJson());
    await firestore.collection("Birds").doc(tern.band).set(tern.toJson());
    //add egg to nest
    await firestore.collection(DateTime
        .now()
        .year
        .toString()).doc(nest.id).collection("egg").doc(egg.id).set(
        egg.toJson());
    await firestore.collection('experiments').doc(experiment.id).set(
        experiment.toJson());

    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});


    myApp = ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
          initialRoute: '/listBirds',
          routes: {
            '/': (context) => MyHomePage(title: "Nest app"),
            '/listBirds': (context) => ListBirds(firestore: firestore),
            '/editBird': (context) => EditBird(firestore: firestore),
          }
      ),
    );


  });

  testWidgets(
      "Will load the list of birds from this year and display them in a list",  (WidgetTester tester) async {
        await tester.pumpWidget(myApp);
        await tester.pumpAndSettle();

        //check if the list of birds is displayed
        expect(find.byType(ListTile), findsNWidgets(2));
});

  testWidgets("will filter birds by species name", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(2));
    //find the filter button
    await tester.tap(find.byIcon(Icons.filter_alt));
    await tester.pumpAndSettle();
    //find the species input

    //find that has the species test in textfield
    // Find the SpeciesRawAutocomplete widget
    Finder speciesRawAutocompleteFinder = find.byType(SpeciesRawAutocomplete);
    expect(speciesRawAutocompleteFinder, findsOneWidget);

    // Find the TextField widget which is a descendant of the SpeciesRawAutocomplete widget
    Finder textFieldFinder = find.descendant(
      of: speciesRawAutocompleteFinder,
      matching: find.byType(TextField),
    );
    expect(textFieldFinder, findsOneWidget);

    // Enter the text "Common gull" into the TextField
    await tester.enterText(textFieldFinder, "Common gull");
    await tester.pumpAndSettle();
    // tap the last item in the list its the popup from the autocomplete
    await tester.tap(find.byType(ListTile).last);
    await tester.pumpAndSettle();

    //tap the close button
    await tester.tap(find.text("Close"));


    //check if the list of birds is displayed
    expect(find.byType(ListTile), findsNWidgets(1));
  });

  testWidgets(
      "Will load the list of birds from 2022 and display them in a list",  (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();
      //find the filter button
      await tester.tap(find.byIcon(Icons.filter_alt));
      await tester.pumpAndSettle();
      //find the year input dropdown
      await tester.tap(find.text(DateTime.now().year.toString()));
      await tester.pumpAndSettle();
        //tap the 2022 year  option
      await tester.tap(find.text("2022"));
      await tester.pumpAndSettle();

      //check if the list of birds is displayed
      expect(find.byType(ListTile), findsNWidgets(1));

  });
  testWidgets(
      "Will load the list of birds from 2023 and display them in a list",  (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    //find the filter button
    await tester.tap(find.byIcon(Icons.filter_alt));
    await tester.pumpAndSettle();
    //find the year input dropdown
    await tester.tap(find.text(DateTime.now().year.toString()));
    await tester.pumpAndSettle();
    //tap the 2022 year  option
    await tester.tap(find.text("2023"));
    await tester.pumpAndSettle();

    //check if the list of birds is displayed
    expect(find.byType(ListTile), findsNWidgets(0));

  });

  testWidgets("can clear all filters", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    //find the filter button
    await tester.tap(find.byIcon(Icons.filter_alt));
    await tester.pumpAndSettle();
    //find the year input dropdown
    await tester.tap(find.text(DateTime.now().year.toString()));
    await tester.pumpAndSettle();
    //tap the 2022 year  option
    await tester.tap(find.text("2022"));
    await tester.pumpAndSettle();
    //find the species input

    await tester.tap(find.byIcon(Icons.filter_alt));
    await tester.pumpAndSettle();
    Finder speciesRawAutocompleteFinder = find.byType(SpeciesRawAutocomplete);
    expect(speciesRawAutocompleteFinder, findsOneWidget);

    // Find the TextField widget which is a descendant of the SpeciesRawAutocomplete widget
    Finder textFieldFinder = find.descendant(
      of: speciesRawAutocompleteFinder,
      matching: find.byType(TextField),
    );
    expect(textFieldFinder, findsOneWidget);

    // Enter the text "Common gull" into the TextField
    await tester.enterText(textFieldFinder, "Common gull");
    await tester.pumpAndSettle();
    // tap the last item in the list its the popup from the autocomplete
    await tester.tap(find.byType(ListTile).last);
    await tester.pumpAndSettle();

    //tap the close button
    await tester.tap(find.text("Clear all"));
    await tester.pumpAndSettle();

    //check if the list of birds is displayed
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets("will show alertdialog when listTile is tapped",
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    //find the search input
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    //check if the list of birds is displayed
    expect(find.byType(AlertDialog), findsOneWidget);

    //expect the downloadChangelog button key to be present
    expect(find.byKey(Key("downloadChangelog")), findsOneWidget);

    //close the dialog
    await tester.tap(find.text("close"));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}