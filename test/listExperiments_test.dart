// Test for listExperiments.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/models/eggStatus.dart';
import 'package:kakrarahu/models/firestore/bird.dart';
import 'package:kakrarahu/models/firestore/egg.dart';
import 'package:kakrarahu/models/firestore/experiment.dart';
import 'package:kakrarahu/models/firestore/nest.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/screens/experiment/editExperiment.dart';
import 'package:kakrarahu/screens/experiment/listExperiments.dart';
import 'package:kakrarahu/screens/homepage.dart';
import 'package:kakrarahu/screens/nest/mapNests.dart';
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
  final Nest nest1 = Nest(
    id: "1",
    coordinates: GeoPoint(0, 0),
    accuracy: "3.22m",
    last_modified: DateTime.now().subtract(Duration(days: 2)),
    discover_date: DateTime.now().subtract(Duration(days: 2)),
    first_egg: DateTime.now().subtract(Duration(days: 2)),
    responsible: "Admin",
    species: "Common gull",
    measures: [Measure.note()],
  );

  final Nest nest2 = Nest(
    id: "2",
    coordinates: GeoPoint(0, 0),
    accuracy: "1.22m",
    last_modified: DateTime.now(),
    discover_date: DateTime.now(),
    responsible: "Admin",
    species: "test",
    measures: [Measure.note()],
  );

  final Nest nest3 = Nest(
    id: "234",
    coordinates: GeoPoint(0, 0),
    accuracy: "3.22m",
    last_modified: DateTime(2023, 6, 1),
    discover_date: DateTime(2023, 5, 1),
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
    year: DateTime.now().year,
    responsible: "Admin",
  );

  final parent = Bird(
      ringed_date: DateTime(2023, 6, 1),
      band: 'AA1234',
      ringed_as_chick: true,
      measures: [Measure.note()],
      nest: "234",
      //2022 was the nest
      nest_year: 2023,
      responsible: 'Admin',
      last_modified: DateTime(2023, 6, 1),
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

  setUpAll(() async {
    AuthService.instance = authService;
    LocationService.instance = locationAccuracy10;

    await firestore.collection('recent').doc("nest").set({"id": "2"});
    await firestore
        .collection(nest1.discover_date.year.toString())
        .doc(nest1.id)
        .set(nest1.toJson());
    await firestore
        .collection(nest2.discover_date.year.toString())
        .doc(nest2.id)
        .set(nest2.toJson());
    await firestore
        .collection(nest3.discover_date.year.toString())
        .doc(nest3.id)
        .set(nest3.toJson());

    await firestore.collection("Birds").doc(parent.band).set(parent.toJson());
    await firestore.collection("Birds").doc(chick.band).set(chick.toJson());
    //add egg to nest
    await firestore
        .collection(DateTime.now().year.toString())
        .doc(nest1.id)
        .collection("egg")
        .doc(egg.id)
        .set(egg.toJson());
    await firestore
        .collection('experiments')
        .doc(experiment.id)
        .set(experiment.toJson());

    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});

    myApp = ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(initialRoute: '/listExperiments', routes: {
        '/': (context) => MyHomePage(title: "Nest app"),
        '/listExperiments': (context) => ListExperiments(firestore: firestore),
        '/editExperiment': (context) => EditExperiment(firestore: firestore),
        '/mapNests': (context) => MapNests(firestore: firestore),
      }),
    );
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

    //close the dialog
    await tester.tap(find.text("close"));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets("will go to nests when map is tapped",
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    //find the map icon on first list tile
    await tester.tap(find.byIcon(Icons.map).first);
    await tester.pumpAndSettle();

    //check if redirected to mapNests
    expect(find.byType(MapNests), findsOneWidget);
  });

  testWidgets("will go to edit experiment when edit is tapped",
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    //find the map icon on first list tile
    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();

    //check if redirected to mapNests
    expect(find.byType(EditExperiment), findsOneWidget);
  });

  testWidgets('List experiments loads', (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(1));
    expect(find.text("New Experiment"), findsOneWidget);
  });

  testWidgets('List experiments loads and can be edited',
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(1));
    //find the edit button and tap it
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    expect(find.byType(EditExperiment), findsOneWidget);
  });

  testWidgets("will filter experiments by year", (WidgetTester tester) async {
    await firestore.collection('experiments').doc("2").set(experiment.toJson());
    experiment.year = 2023;
    await firestore.collection('experiments').doc("3").set(experiment.toJson());
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.filter_alt));
    await tester.pumpAndSettle();
    await tester.tap(find.text(DateTime.now().year.toString()));
    await tester.pumpAndSettle();
    //tap the 2023 year  option
    await tester.tap(find.text("2023"));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(1));
  });

  testWidgets("can add new experiment", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byType(EditExperiment), findsOneWidget);
  });

  testWidgets("can search for experiment", (WidgetTester tester) async {
    experiment.name = "test";
    await firestore.collection('experiments').doc("2").set(experiment.toJson());
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), "New");
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets("will raise download experiment dialog",
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.download));
    await tester.pump(Duration(milliseconds: 500));
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text("OK"));
    await tester.pumpAndSettle();

    //check that alert dialog is gone
    expect(find.byType(AlertDialog), findsNothing);
  });
}
