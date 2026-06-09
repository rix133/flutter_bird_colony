// Test for listExperiments.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/eggStatus.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/models/firestore/egg.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_bird_colony/screens/experiment/editExperiment.dart';
import 'package:flutter_bird_colony/screens/experiment/listExperiments.dart';
import 'package:flutter_bird_colony/screens/homepage.dart';
import 'package:flutter_bird_colony/screens/nest/mapNests.dart';
import 'package:flutter_bird_colony/services/locationService.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/mockAuthService.dart';
import 'mocks/mockLocationService.dart';
import 'mocks/mockSharedPreferencesService.dart';
import 'testApp.dart';

void main() {
  final authService = MockAuthService();
  final sharedPreferencesService = MockSharedPreferencesService();
  final firestore = FakeFirebaseFirestore();
  MockLocationAccuracy10 locationAccuracy10 = MockLocationAccuracy10();
  late TestApp myApp;
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
  group('Navigation and loading', () {
    setUpAll(() async {
      //AuthService.instance = authService;
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

      await firestore
          .collection('users')
          .doc(userEmail)
          .set({'isAdmin': false});

      myApp = TestApp(
        firestore: firestore,
        sps: sharedPreferencesService,
        app: MaterialApp(initialRoute: '/listExperiments', routes: {
          '/': (context) => MyHomePage(title: "Nest app", auth: authService),
          '/listExperiments': (context) =>
              ListExperiments(firestore: firestore),
          '/editExperiment': (context) => EditExperiment(firestore: firestore),
          '/mapNests': (context) =>
              MapNests(firestore: firestore, auth: authService),
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
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(find.text("Description: Test experiment"), findsOneWidget);

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
      expect(find.text("New Experiment - Test experiment"), findsOneWidget);
    });

    testWidgets("can add new experiment", (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.byType(EditExperiment), findsOneWidget);
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
  });

  group('Filtering', () {
    setUpAll(() async {
      //AuthService.instance = authService;
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

      await firestore
          .collection('experiments')
          .doc("2")
          .set(experiment.toJson());
      experiment.year = 2023;
      await firestore
          .collection('experiments')
          .doc("3")
          .set(experiment.toJson());

      await firestore
          .collection('users')
          .doc(userEmail)
          .set({'isAdmin': false});

      myApp = TestApp(
        firestore: firestore,
        sps: sharedPreferencesService,
        app: MaterialApp(initialRoute: '/listExperiments', routes: {
          '/': (context) => MyHomePage(title: "Nest app", auth: authService),
          '/listExperiments': (context) =>
              ListExperiments(firestore: firestore),
          '/editExperiment': (context) => EditExperiment(firestore: firestore),
          '/mapNests': (context) =>
              MapNests(firestore: firestore, auth: authService),
        }),
      );
    });

    testWidgets("will filter experiments by year", (WidgetTester tester) async {
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

    testWidgets("will filter experiments by text", (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(2));
      await tester.enterText(find.byKey(Key('searchTextField')), "10");
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(0));
    });

    testWidgets("can search for experiment", (WidgetTester tester) async {
      experiment.name = "test";
      await firestore
          .collection('experiments')
          .doc("2")
          .set(experiment.toJson());
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), "New");
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
    });
  });

  group('Bulk nest checked actions', () {
    testWidgets("can mark and unmark experiment nests checked today",
        (WidgetTester tester) async {
      final localFirestore = FakeFirebaseFirestore();
      final localSps = MockSharedPreferencesService();
      localSps.isAdmin = true;
      final year = DateTime.now().year;
      final oldDate = DateTime.now().subtract(Duration(days: 5));
      final bulkExperiment = Experiment(
        id: "bulk_exp",
        name: "Bulk check experiment",
        description: "Nest check subset",
        last_modified: oldDate,
        created: oldDate,
        year: year,
        nests: ["bulk1", "bulk2", "missing"],
        responsible: "Admin",
      );
      final bulkNest1 = Nest(
        id: "bulk1",
        coordinates: GeoPoint(0, 0),
        accuracy: "3.22m",
        last_modified: oldDate,
        discover_date: oldDate,
        responsible: "Admin",
        species: "Common gull",
        remark: "keep remark",
        measures: [Measure.note()],
      );
      final bulkNest2 = Nest(
        id: "bulk2",
        coordinates: GeoPoint(0, 0),
        accuracy: "1.22m",
        last_modified: oldDate,
        discover_date: oldDate,
        responsible: "Admin",
        species: "Common gull",
        measures: [Measure.note()],
      );

      await localFirestore
          .collection(year.toString())
          .doc(bulkNest1.id)
          .set(bulkNest1.toJson());
      await localFirestore
          .collection(year.toString())
          .doc(bulkNest2.id)
          .set(bulkNest2.toJson());
      await localFirestore
          .collection('experiments')
          .doc(bulkExperiment.id)
          .set(bulkExperiment.toJson());

      final app = TestApp(
        firestore: localFirestore,
        sps: localSps,
        app: MaterialApp(initialRoute: '/listExperiments', routes: {
          '/listExperiments': (context) =>
              ListExperiments(firestore: localFirestore),
          '/editExperiment': (context) =>
              EditExperiment(firestore: localFirestore),
          '/mapNests': (context) =>
              MapNests(firestore: localFirestore, auth: authService),
        }),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key("markExperimentNestsChecked_bulk_exp")));
      await tester.pumpAndSettle();
      expect(find.text("Mark nests checked today?"), findsOneWidget);
      expect(
          find.textContaining("without changing their real last modified date"),
          findsOneWidget);

      await tester.tap(find.text("Mark checked"));
      await tester.pumpAndSettle();

      Nest markedNest1 = Nest.fromDocSnapshot(await localFirestore
          .collection(year.toString())
          .doc(bulkNest1.id)
          .get());
      Nest markedNest2 = Nest.fromDocSnapshot(await localFirestore
          .collection(year.toString())
          .doc(bulkNest2.id)
          .get());
      final markedNest1Data = (await localFirestore
              .collection(year.toString())
              .doc(bulkNest1.id)
              .get())
          .data()!;

      expect(markedNest1.checkedToday(), true);
      expect(markedNest2.checkedToday(), true);
      expect(markedNest1.last_modified, oldDate);
      expect(markedNest2.last_modified, oldDate);
      expect(markedNest1.bulk_checked, isNotNull);
      expect(markedNest2.bulk_checked, isNotNull);
      expect(markedNest1.bulk_checked_dates, hasLength(1));
      expect(markedNest2.bulk_checked_dates, hasLength(1));
      expect(markedNest1.bulk_checked_dates.single, markedNest1.bulk_checked);
      expect(markedNest2.bulk_checked_dates.single, markedNest2.bulk_checked);
      expect(markedNest1Data["remark"], "keep remark");
      expect(find.text("Marked 2 nests checked today"), findsOneWidget);

      await tester
          .tap(find.byKey(Key("uncheckExperimentNestsChecked_bulk_exp")));
      await tester.pumpAndSettle();
      expect(find.text("Uncheck nests today?"), findsOneWidget);
      expect(
          find.textContaining("without changing their real last modified date"),
          findsOneWidget);

      await tester.tap(find.text("Uncheck"));
      await tester.pumpAndSettle();

      final uncheckedNest1 = Nest.fromDocSnapshot(await localFirestore
          .collection(year.toString())
          .doc(bulkNest1.id)
          .get());
      final uncheckedNest2 = Nest.fromDocSnapshot(await localFirestore
          .collection(year.toString())
          .doc(bulkNest2.id)
          .get());

      expect(uncheckedNest1.checkedToday(), false);
      expect(uncheckedNest2.checkedToday(), false);
      expect(uncheckedNest1.last_modified, oldDate);
      expect(uncheckedNest2.last_modified, oldDate);
      expect(uncheckedNest1.bulk_checked, isNull);
      expect(uncheckedNest2.bulk_checked, isNull);
      expect(uncheckedNest1.bulk_checked_dates, hasLength(1));
      expect(uncheckedNest2.bulk_checked_dates, hasLength(1));
      expect(find.text("Unchecked 2 nests for today"), findsOneWidget);
    });

    testWidgets("bulk nest checked action can be cancelled",
        (WidgetTester tester) async {
      final localFirestore = FakeFirebaseFirestore();
      final localSps = MockSharedPreferencesService();
      localSps.isAdmin = true;
      final year = DateTime.now().year;
      final oldDate = DateTime.now().subtract(Duration(days: 5));
      final bulkExperiment = Experiment(
        id: "cancel_bulk_exp",
        name: "Cancel bulk experiment",
        last_modified: oldDate,
        created: oldDate,
        year: year,
        nests: ["cancel_bulk1"],
      );
      final bulkNest = Nest(
        id: "cancel_bulk1",
        coordinates: GeoPoint(0, 0),
        accuracy: "3.22m",
        last_modified: oldDate,
        discover_date: oldDate,
        responsible: "Admin",
        species: "Common gull",
        measures: [Measure.note()],
      );

      await localFirestore
          .collection(year.toString())
          .doc(bulkNest.id)
          .set(bulkNest.toJson());
      await localFirestore
          .collection('experiments')
          .doc(bulkExperiment.id)
          .set(bulkExperiment.toJson());

      final app = TestApp(
        firestore: localFirestore,
        sps: localSps,
        app: MaterialApp(initialRoute: '/listExperiments', routes: {
          '/listExperiments': (context) =>
              ListExperiments(firestore: localFirestore),
          '/editExperiment': (context) =>
              EditExperiment(firestore: localFirestore),
          '/mapNests': (context) =>
              MapNests(firestore: localFirestore, auth: authService),
        }),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(Key("markExperimentNestsChecked_cancel_bulk_exp")));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Cancel"));
      await tester.pumpAndSettle();

      final unchangedNest = Nest.fromDocSnapshot(await localFirestore
          .collection(year.toString())
          .doc(bulkNest.id)
          .get());
      expect(unchangedNest.checkedToday(), false);
      expect(unchangedNest.last_modified, oldDate);
      expect(unchangedNest.bulk_checked, isNull);
      expect(unchangedNest.bulk_checked_dates, isEmpty);
    });

    testWidgets("bulk nest checked buttons are hidden for non-admin users",
        (WidgetTester tester) async {
      final localFirestore = FakeFirebaseFirestore();
      final localSps = MockSharedPreferencesService();
      final year = DateTime.now().year;
      final oldDate = DateTime.now().subtract(Duration(days: 5));
      final bulkExperiment = Experiment(
        id: "non_admin_bulk_exp",
        name: "Non-admin bulk experiment",
        last_modified: oldDate,
        created: oldDate,
        year: year,
        nests: ["non_admin_bulk1"],
      );
      final bulkNest = Nest(
        id: "non_admin_bulk1",
        coordinates: GeoPoint(0, 0),
        accuracy: "3.22m",
        last_modified: oldDate,
        discover_date: oldDate,
        responsible: "Admin",
        species: "Common gull",
        measures: [Measure.note()],
      );

      await localFirestore
          .collection(year.toString())
          .doc(bulkNest.id)
          .set(bulkNest.toJson());
      await localFirestore
          .collection('experiments')
          .doc(bulkExperiment.id)
          .set(bulkExperiment.toJson());

      final app = TestApp(
        firestore: localFirestore,
        sps: localSps,
        app: MaterialApp(initialRoute: '/listExperiments', routes: {
          '/listExperiments': (context) =>
              ListExperiments(firestore: localFirestore),
          '/editExperiment': (context) =>
              EditExperiment(firestore: localFirestore),
          '/mapNests': (context) =>
              MapNests(firestore: localFirestore, auth: authService),
        }),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.byKey(Key("markExperimentNestsChecked_non_admin_bulk_exp")),
          findsNothing);
      expect(
          find.byKey(Key("uncheckExperimentNestsChecked_non_admin_bulk_exp")),
          findsNothing);
    });
  });

  group('Exporting', () {
    setUpAll(() async {
      //AuthService.instance = authService;
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

      await firestore
          .collection('users')
          .doc(userEmail)
          .set({'isAdmin': false});

      myApp = TestApp(
        firestore: firestore,
        sps: sharedPreferencesService,
        app: MaterialApp(initialRoute: '/listExperiments', routes: {
          '/': (context) => MyHomePage(title: "Nest app", auth: authService),
          '/listExperiments': (context) =>
              ListExperiments(firestore: firestore),
          '/editExperiment': (context) => EditExperiment(firestore: firestore),
          '/mapNests': (context) =>
              MapNests(firestore: firestore, auth: authService),
        }),
      );
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
  });
}
