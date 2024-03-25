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
import 'package:kakrarahu/screens/listMeasures.dart';
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
    accuracy: "12.22m",
    last_modified: DateTime.now().subtract(Duration(days: 2)),
    discover_date: DateTime.now().subtract(Duration(days: 2)),
    first_egg: DateTime.now().subtract(Duration(days: 2)),
    responsible: "Admin",
    species: "Common gull",
    measures: [Measure.note()],
  );

  Nest nest2 = Nest(
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
    accuracy: "12.22m",
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
  Experiment experiment = Experiment(
      id: "1",
      name: "New Experiment",
      type: "nest",
      description: "Test experiment",
      last_modified: DateTime.now(),
      created: DateTime.now(),
      year: DateTime.now().year,
      responsible: "Admin",
      nests: ["2"],
      measures: []);

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

  getInitApp(dynamic arguments) {
    return ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
        initialRoute: '/editExperiment',
        onGenerateRoute: (settings) {
          if (settings.name == '/editExperiment') {
            return MaterialPageRoute(
              builder: (context) => EditExperiment(
                firestore: firestore,
              ),
              settings: RouteSettings(
                arguments: arguments, // get initial nest from object
              ),
            );
          }
          if (settings.name == '/listExperiments') {
            return MaterialPageRoute(
              builder: (context) => ListExperiments(
                firestore: firestore,
              ),
            );
          }
          // Other routes...
          return MaterialPageRoute(
            builder: (context) => MyHomePage(title: "Nest app"),
          );
        },
      ),
    );
  }

  setUpAll(() async {
    AuthService.instance = authService;
    LocationService.instance = locationAccuracy10;

    await firestore.collection('recent').doc("nest").set({"id": "2"});
    await firestore
        .collection(nest1.discover_date.year.toString())
        .doc(nest1.id)
        .set(nest1.toJson());
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

    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});
  });

  setUp(() async {
    experiment = Experiment(
        id: "1",
        name: "New Experiment",
        type: "nest",
        description: "Test experiment",
        last_modified: DateTime.now(),
        created: DateTime.now(),
        year: DateTime.now().year,
        responsible: "Admin",
        nests: ["2"],
        measures: []);
    experiment.previousNests = [
      "2"
    ]; //set this manually because it is not saved to firestore
    nest2 = Nest(
        id: "2",
        coordinates: GeoPoint(0, 0),
        accuracy: "1.22m",
        last_modified: DateTime.now(),
        discover_date: DateTime.now(),
        responsible: "Admin",
        species: "test",
        measures: [Measure.note()],
        experiments: [experiment]);
    await firestore
        .collection(nest2.discover_date.year.toString())
        .doc(nest2.id)
        .set(nest2.toJson());
    await firestore
        .collection('experiments')
        .doc(experiment.id)
        .set(experiment.toJson());
  });

  tearDown(() async {
    //empty the experiment collection
    await firestore
        .collection('experiments')
        .get()
        .then((value) => value.docs.forEach((element) async {
              await element.reference.delete();
            }));
  });

  testWidgets('Will load new experiment', (WidgetTester tester) async {
    myApp = getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    expect(find.text("Edit Experiment"), findsOneWidget);
  });

  testWidgets("can add new nest to experiment", (WidgetTester tester) async {
    myApp = getInitApp(experiment);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    //searhctext new Experiment
    expect(find.text("New Experiment"), findsOneWidget);

    //search button new nests and tap it
    await tester.tap(find.text("Select nests"));
    await tester.pumpAndSettle();

    //tap first listTile
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(find.text("Nest ID: 1"), findsOneWidget);
  });

  testWidgets('can pick experiment color', (WidgetTester tester) async {
    myApp = getInitApp(experiment);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    //searhctext new Experiment
    expect(find.text("New Experiment"), findsOneWidget);

    //search button and tap it
    await tester.tap(find.text("Pick color"));
    await tester.pumpAndSettle();

    // tap Got it
    await tester.tap(find.text("Got it"));
    await tester.pumpAndSettle();
  });

  testWidgets('can add new measure to existing experiment',
      (WidgetTester tester) async {
    myApp = getInitApp(experiment);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //expect that there are no listiles under ListMeasures widget

    //find Listmeasures widget
    expect(find.byType(ListMeasures), findsOneWidget);

    //find children of ListMeasures widget
    Finder listMeasures = find.byType(ListMeasures);
    expect(find.descendant(of: listMeasures, matching: find.byType(ListTile)),
        findsNothing);

    Finder addMeasureButton = find.byKey(Key("addMeasureButton"));
    await tester.ensureVisible(addMeasureButton);
    await tester.tap(addMeasureButton);
    await tester.pumpAndSettle();

    expect(find.descendant(of: listMeasures, matching: find.byType(ListTile)),
        findsOneWidget);

    await tester.tap(find.text("Add measure"));
    await tester.pumpAndSettle();

    expect(find.descendant(of: listMeasures, matching: find.byType(ListTile)),
        findsNWidgets(2));
  });

  testWidgets('can add new measure to new experiment',
      (WidgetTester tester) async {
    myApp = getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //expect that there are no listiles under ListMeasures widget

    //find Listmeasures widget
    expect(find.byType(ListMeasures), findsOneWidget);

    //find children of ListMeasures widget
    Finder listMeasures = find.byType(ListMeasures);
    expect(find.descendant(of: listMeasures, matching: find.byType(ListTile)),
        findsNothing);

    Finder addMeasureButton = find.byKey(Key("addMeasureButton"));
    await tester.ensureVisible(addMeasureButton);
    await tester.tap(addMeasureButton);
    await tester.pumpAndSettle();

    expect(find.descendant(of: listMeasures, matching: find.byType(ListTile)),
        findsOneWidget);

    await tester.tap(find.text("Add measure"));
    await tester.pumpAndSettle();

    expect(find.descendant(of: listMeasures, matching: find.byType(ListTile)),
        findsNWidgets(2));
  });

  testWidgets("saves experiment measures to firestore",
      (WidgetTester tester) async {
    myApp = getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //set the name
    await tester.enterText(
        find.byKey(Key("experimentNameField")), "test experiment");
    await tester.pumpAndSettle();

    //add a measure
    final addMeasureButton = find.byKey(Key("addMeasureButton"));
    expect(addMeasureButton, findsOneWidget);

    await tester.ensureVisible(addMeasureButton);
    await tester.tap(addMeasureButton);
    await tester.pumpAndSettle();

    //find the edit button under added measure
    final editButton = find.byIcon(Icons.edit);
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key("nameMeasureEdit")), "test measure");

    //find the 3 switchListTiles and toggle them
    final switchListTiles = find.byType(SwitchListTile);
    expect(switchListTiles, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      await tester.tap(switchListTiles.at(i));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(Key("doneMeasureEditButton")));
    await tester.pumpAndSettle();

    final saveButton = find.byKey(Key("saveButton"));
    expect(saveButton, findsOneWidget);

    //ensure visible
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    QuerySnapshot query = await firestore.collection('experiments').get();
    List<QueryDocumentSnapshot> docs = query.docs;
    expect(docs.length, 2);
    List<Experiment> experiments =
        docs.map((e) => Experiment.fromDocSnapshot(e)).toList();

    //get the new experiment
    Experiment? dfObj =
        experiments.firstWhere((element) => element.name == "test experiment");

    expect(dfObj.measures.length, 1);
    expect(dfObj.measures[0].name, "test measure");
    expect(dfObj.measures[0].isNumber, true);
    expect(dfObj.measures[0].type, "any");
    expect(dfObj.measures[0].unit, "");
    expect(dfObj.measures[0].value, "");
    expect(dfObj.measures[0].required, true);
    expect(dfObj.measures[0].repeated, true);
  });

  testWidgets("can change experiment type to bird",
      (WidgetTester tester) async {
    myApp = getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //find the dropdown
    Finder dropdown = find.byType(DropdownButton);
    expect(dropdown, findsOneWidget);

    //tap the dropdown
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    //tap the bird option
    await tester.tap(find.text("Bird"));
    await tester.pumpAndSettle();

    //expect that the dropdown value is bird
    expect(find.text("Bird"), findsOneWidget);
  });

  testWidgets("can save a new experiment", (WidgetTester tester) async {
    myApp = getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //search button new nests and tap it
    await tester.tap(find.text("Select nests"));
    await tester.pumpAndSettle();

    //tap first listTile
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    //set the name
    await tester.enterText(
        find.byKey(Key("experimentNameField")), "test experiment");

    //find the save button
    Finder saveButton = find.byKey(Key("saveButton"));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);

    //tap the save button
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    //check firestore for the new experiment fwt all experiments and filter by name
    QuerySnapshot query = await firestore.collection('experiments').get();
    List<QueryDocumentSnapshot> docs = query.docs;
    expect(docs.length, 2);
    List<Experiment> experiments =
        docs.map((e) => Experiment.fromDocSnapshot(e)).toList();
    //get the new experiment
    Experiment? newExperiment =
        experiments.firstWhere((element) => element.name == "test experiment");
    expect(newExperiment, isNotNull);
    expect(newExperiment.type, "nest");
    expect(newExperiment.nests!.length, 1);

    //get the nest 1
    DocumentSnapshot nestDoc = await firestore
        .collection(DateTime.now().year.toString())
        .doc("1")
        .get();
    Nest nest = Nest.fromDocSnapshot(nestDoc);
    //expect that the nest has the new experiment
    expect(nest.experiments!.length, 1);
  });

  testWidgets("can edit an existing experiment", (WidgetTester tester) async {
    //get the nest 2
    DocumentSnapshot nestDoc = await firestore
        .collection(DateTime.now().year.toString())
        .doc("2")
        .get();
    Nest nest = Nest.fromDocSnapshot(nestDoc);
    //expect that the nest has the new experiment
    expect(nest.experiments!.length, 1);
    expect(nest.experiments!.first.name, "New Experiment");

    myApp = getInitApp(experiment);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //set the name
    await tester.enterText(
        find.byKey(Key("experimentNameField")), "test experiment");

    //find the save button
    Finder saveButton = find.byKey(Key("saveButton"));
    await tester.ensureVisible(saveButton);

    //tap the save button
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    //get the experiment 1
    DocumentSnapshot experimentDoc =
        await firestore.collection('experiments').doc("1").get();
    Experiment newExperiment = Experiment.fromDocSnapshot(experimentDoc);
    expect(newExperiment.name, "test experiment");

    //get the nest 2
    nestDoc = await firestore
        .collection(DateTime.now().year.toString())
        .doc("2")
        .get();
    nest = Nest.fromDocSnapshot(nestDoc);
    //expect that the nest has the new experiment
    expect(nest.experiments!.length, 1);
    expect(nest.experiments!.first.name, "test experiment");
  });

  testWidgets("will remove existing nest from experiment",
      (WidgetTester tester) async {
    myApp = getInitApp(experiment);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    //searhctext new Experiment
    expect(find.text("New Experiment"), findsOneWidget);

    expect(find.text("Nest ID: 2"), findsOneWidget);
    //search the close button and tap it
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text("Nest ID: 2"), findsNothing);

    //find the save button
    Finder saveButton = find.byKey(Key("saveButton"));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);

    //tap the save button
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    //get the experiment 1
    DocumentSnapshot experimentDoc =
        await firestore.collection('experiments').doc("1").get();
    Experiment newExperiment = Experiment.fromDocSnapshot(experimentDoc);
    expect(newExperiment.nests!.length, 0);

    //get the nest 2
    DocumentSnapshot nestDoc = await firestore
        .collection(DateTime.now().year.toString())
        .doc("2")
        .get();
    Nest nest = Nest.fromDocSnapshot(nestDoc);
    //expect that the nest has no experiments
    expect(nest.experiments?.length, 0);
  });

  testWidgets("will delete existing experiment", (WidgetTester tester) async {
    myApp = getInitApp(experiment);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    //searhctext new Experiment
    expect(find.text("New Experiment"), findsOneWidget);

    //find the delete button
    Finder deleteButton = find.byIcon(Icons.delete);
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    //search the delete confirmation button and tap it
    await tester.tap(find.text("Delete"));
    await tester.pumpAndSettle();

    //get the experiment 1
    DocumentSnapshot experimentDoc =
        await firestore.collection('experiments').doc("1").get();
    expect(experimentDoc.exists, false);

    //get the nest 2
    DocumentSnapshot nestDoc = await firestore
        .collection(DateTime.now().year.toString())
        .doc("2")
        .get();
    Nest nest = Nest.fromDocSnapshot(nestDoc);
    //expect that the nest has no experiments
    expect(nest.experiments?.length, 0);
  });
}
