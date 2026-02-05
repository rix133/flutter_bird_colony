import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/speciesRawAutocomplete.dart';
import 'package:flutter_bird_colony/models/eggStatus.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/models/firestore/egg.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_bird_colony/screens/bird/editBird.dart';
import 'package:flutter_bird_colony/screens/homepage.dart';
import 'package:flutter_bird_colony/screens/nest/editEgg.dart';
import 'package:flutter_bird_colony/screens/nest/editNest.dart';
import 'package:flutter_bird_colony/screens/nest/findNest.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_bird_colony/services/locationService.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'mocks/mockAuthService.dart';
import 'mocks/mockLocationService.dart';
import 'mocks/mockSharedPreferencesService.dart';

void main() {
  final authService = MockAuthService();
  final storage = MockFirebaseStorage();
  final sharedPreferencesService = MockSharedPreferencesService();
  final firestore = FakeFirebaseFirestore();
  MockLocationAccuracy10 locationAccuracy10 = MockLocationAccuracy10();
  late Widget myApp;
  final userEmail = "test@example.com";
  final Nest nest = Nest(
    id: "1",
    coordinates: GeoPoint(0, 0),
    accuracy: "3.22m",
    last_modified: DateTime.now().subtract(Duration(days: 1)),
    discover_date: DateTime.now().subtract(Duration(days: 2)),
    first_egg: DateTime.now().subtract(Duration(days: 2)),
    responsible: "Admin",
    species: "Common gull",
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

  Future<Widget> getMyApp() async {
    //AuthService.instance = authService;
    LocationService.instance = locationAccuracy10;
    sharedPreferencesService.defaultMeasures = [
      Measure.numeric(name: "weight", type: "chick"),
      Measure.numeric(name: "test", type: "egg", required: true),
    ];
    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});
    myApp = ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
        initialRoute: '/editNest',
        onGenerateRoute: (settings) {
          if (settings.name == '/editNest') {
            return MaterialPageRoute(
              builder: (context) => EditNest(
                firestore: firestore,
                storage: storage,
              ),
              settings: RouteSettings(
                arguments: {'nest_id': nest.id}, // get initial nest from object
              ),
            );
          } else if (settings.name == '/findNest') {
            return MaterialPageRoute(
              builder: (context) => FindNest(
                firestore: firestore,
              ),
            );
          } else if (settings.name == '/editEgg') {
            return MaterialPageRoute(
              builder: (context) => EditEgg(
                firestore: firestore,
              ),
              settings: RouteSettings(
                arguments: egg, // get initial nest from object
              ),
            );
          } else if (settings.name == '/editBird') {
            return MaterialPageRoute(
              builder: (context) => EditBird(
                firestore: firestore,
              ),
              settings: settings,
            );
          }
          // Other routes...
          return MaterialPageRoute(
            builder: (context) =>
                MyHomePage(title: "Nest app", auth: authService),
          );
        },
      ),
    );
    return myApp;
  }

  ;
  group("make new Bird", () {
    setUp(() async {
      //reset the database
      await firestore.collection('recent').doc("nest").set({"id": "1"});
      await nest.save(firestore);
      //add egg to nest
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .set(egg.toJson());
      myApp = await getMyApp();
    });

    tearDown(() async {
      await firestore.collection("Birds").doc("BB1235").delete();
      //delete nest egg
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .delete();
      //delete nest
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .delete();
    });

    testWidgets("will add a new parent when parent is saved",
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text('add parent'));
      await tester.pumpAndSettle();

      expect(find.byType(EditBird), findsOneWidget);
      //find the letters and numbers inputs
      await tester.enterText(find.byKey(Key("band_letCntr")), "bb");
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key("band_numCntr")), "1235");
      await tester.pumpAndSettle();

      //save the bird
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();
      //expect to find the bird in firestore
      var bird = await firestore.collection("Birds").doc("BB1235").get();
      expect(bird.exists, true);
      Bird newBird = Bird.fromDocSnapshot(bird);
      expect(newBird.id, "BB1235");
      expect(newBird.species, "Common gull");
      expect(newBird.nest, "1");
      expect(newBird.nest_year, nest.discover_date.year);
      expect(newBird.isChick(), false);

      Nest nestObj = Nest.fromDocSnapshot(await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .get());
      expect(nestObj.parents?.length, 1);
      expect(nestObj.parents?[0].band, "BB1235");
    });

    testWidgets(
        "will show no validation errors when egg with missing required measures is ringed",
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Egg 1 intact 2 days old'));
      await tester.pumpAndSettle();

      expect(find.byType(EditEgg), findsOneWidget);
      //tap on save button
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      //expecte an alert dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      //tap on save anyway
      await tester.tap(find.text("save anyway"));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Egg 1 intact 2 days old'));
      await tester.pumpAndSettle();

      expect(find.byType(EditBird), findsOneWidget);

      //find the letters and numbers inputs
      await tester.enterText(find.byKey(Key("band_letCntr")), "bb");
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key("band_numCntr")), "1235");
      await tester.pumpAndSettle();

      //save the bird
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      //show no validation errors
      expect(find.byType(AlertDialog), findsNothing);

      //expect to find the bird in firestore
      var bird = await firestore.collection("Birds").doc("BB1235").get();
      expect(bird.exists, true);
      Bird newBird = Bird.fromDocSnapshot(bird);
      expect(newBird.id, "BB1235");
      expect(newBird.species, "Common gull");
      expect(newBird.nest, "1");
      expect(newBird.nest_year, nest.discover_date.year);
      expect(newBird.ringed_as_chick, true);
      expect(newBird.isChick(), true);

      Egg eggObj = Egg.fromDocSnapshot(await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .get());
      expect(eggObj.ring, "BB1235");
      expect(eggObj.status.toString(), "hatched");
    });

    testWidgets("will add a bird when egg is long pressed",
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Egg 1 intact 2 days old'));
      await tester.pumpAndSettle();

      expect(find.byType(EditBird), findsOneWidget);

      //find the letters and numbers inputs
      await tester.enterText(find.byKey(Key("band_letCntr")), "bb");
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key("band_numCntr")), "1235");
      await tester.pumpAndSettle();

      //save the bird
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();
      //expect to find the bird in firestore
      var bird = await firestore.collection("Birds").doc("BB1235").get();
      expect(bird.exists, true);
      Bird newBird = Bird.fromDocSnapshot(bird);
      expect(newBird.id, "BB1235");
      expect(newBird.species, "Common gull");
      expect(newBird.nest, "1");
      expect(newBird.nest_year, nest.discover_date.year);
      expect(newBird.ringed_as_chick, true);
      expect(newBird.isChick(), true);

      Egg eggObj = Egg.fromDocSnapshot(await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .get());
      expect(eggObj.ring, "BB1235");
      expect(eggObj.status.toString(), "hatched");
    });

    testWidgets(
        "will add a bird when egg is long pressed an will show chick weight",
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Egg 1 intact 2 days old'));
      await tester.pumpAndSettle();

      expect(find.byType(EditBird), findsOneWidget);

      //find the letters and numbers inputs
      await tester.enterText(find.byKey(Key("band_letCntr")), "bb");
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key("band_numCntr")), "1235");
      await tester.pumpAndSettle();

      Finder noteFinder = find.byWidgetPredicate((Widget widget) =>
          widget is InputDecorator && widget.decoration.labelText == 'note');

      expect(noteFinder, findsOneWidget, reason: "note input not found");

      Finder textFinder = find.byWidgetPredicate((Widget widget) =>
          widget is InputDecorator && widget.decoration.labelText == 'weight');

      expect(textFinder, findsOneWidget, reason: "weight input not found");
      await tester.enterText(textFinder, "100");
      await tester.pumpAndSettle();

      //save the bird
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();
      //expect to find the bird in firestore
      var bird = await firestore.collection("Birds").doc("BB1235").get();
      expect(bird.exists, true);
      Bird newBird = Bird.fromDocSnapshot(bird);
      expect(newBird.id, "BB1235");
      expect(newBird.species, "Common gull");
      expect(newBird.nest, "1");
      expect(newBird.nest_year, nest.discover_date.year);
      expect(newBird.ringed_as_chick, true);
      expect(newBird.measures.length, 2);
      expect(newBird.measures[1].name, "weight");
      expect(newBird.measures[1].value, "100");
      expect(newBird.isChick(), true);

      Egg eggObj = Egg.fromDocSnapshot(await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .get());
      expect(eggObj.ring, "BB1235");
      expect(eggObj.status.toString(), "hatched");
    });

    testWidgets("will add bird when add egg is long pressed",
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.longPress(find.text('add egg'));
      await tester.pumpAndSettle();

      expect(find.byType(EditBird), findsOneWidget);

      //find the letters and numbers inputs
      await tester.enterText(find.byKey(Key("band_letCntr")), "bb");
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key("band_numCntr")), "1235");
      await tester.pumpAndSettle();

      //save the bird
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();
      //expect to find the bird in firestore
      var bird = await firestore.collection("Birds").doc("BB1235").get();
      expect(bird.exists, true);
      Bird newBird = Bird.fromDocSnapshot(bird);
      expect(newBird.id, "BB1235");
      expect(newBird.species, "Common gull");
      expect(newBird.nest, "1");
      expect(newBird.nest_year, nest.discover_date.year);
      expect(newBird.ringed_as_chick, true);
      expect(newBird.isChick(), true);

      Egg eggObj = Egg.fromDocSnapshot(await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc("1 chick BB1235")
          .get());
      expect(eggObj.ring, "BB1235");
      expect(eggObj.status.toString(), "hatched");
      expect(eggObj.discover_date, newBird.ringed_date);
    });

    testWidgets("will update ringed count when egg ringed",
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //has Ringed(0) shown
      expect(find.text("Ringed (0)"), findsOneWidget);

      await tester.longPress(find.text('Egg 1 intact 2 days old'));
      await tester.pumpAndSettle();

      expect(find.byType(EditBird), findsOneWidget);

      //find the letters and numbers inputs
      await tester.enterText(find.byKey(Key("band_letCntr")), "bb");
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key("band_numCntr")), "1235");
      await tester.pumpAndSettle();

      //save the bird
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();
      //expect to be redirected to the nest
      expect(find.byType(EditNest), findsOneWidget);
      expect(find.text("Ringed (1)"), findsOneWidget,
          reason: "Ringed count not updated after save");
    });

    testWidgets("will show ringed count when egg is ringed",
        (WidgetTester tester) async {
      await firestore.collection("Birds").doc("BB1235").set({
        "id": "BB1235",
        "species": "Common gull",
        "nest": "1",
        "nest_year": nest.discover_date.year,
        "ringed_as_chick": true,
        "ringed_date": DateTime.now().subtract(Duration(days: 1)),
      });
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .update({"ring": "BB1235", "status": "hatched"});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //has Ringed(0) shown
      expect(find.text("Ringed (1)"), findsOneWidget);
    });
  });

  group("validate required measures", () {
    setUp(() async {
      //reset the database
      nest.accuracy = "3.22m";
      await firestore.collection('recent').doc("nest").set({"id": "1"});
      await nest.save(firestore);
      egg.measures = [Measure.numeric(name: "weight", unit: "")];
      //add egg to nest
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .set(egg.toJson());

      myApp = await getMyApp();
    });

    tearDown(() async {
      //delete all nest eggs
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .get()
          .then((value) {
        value.docs.forEach((element) {
          element.reference.delete();
        });
      });

      //delete nest
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .delete();
    });

    testWidgets("will save nest when no required measures on egg",
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();
      //expect to find the egg in firestore
      var eggObj = await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .get();
      expect(eggObj.exists, true);
      Egg newEgg = Egg.fromDocSnapshot(eggObj);
      expect(newEgg.id, "1 egg 1");
      expect(newEgg.status.toString(), "intact");
      //the other one is an empty note
      expect(newEgg.measures.length, 2);
      expect(newEgg.measures[0].name, "note");
      expect(newEgg.measures[0].value, "");
      expect(newEgg.measures[1].name, "weight");
      expect(newEgg.measures[1].value, "");

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets("will raise an alertdialog with 2 errors",
        (WidgetTester tester) async {
      nest.accuracy = "13.22m";
      egg.measures = [
        Measure.numeric(name: "weight", unit: "", required: true)
      ];
      await nest.save(firestore);
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .set(egg.toJson());
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      expect(find.text("Validation failed (2 errors)"), findsOneWidget);
      expect(find.text("Nest location accuracy is over 4.0 m"), findsOneWidget);
      expect(
          find.text("Measure weight on egg 1 is required but not filled in!"),
          findsOneWidget);
    });

    testWidgets("will not save nest when required measures on egg are empty",
        (WidgetTester tester) async {
      Measure m1 = Measure.numeric(name: "weight", unit: "", required: true);
      Egg egg2 = Egg(
          id: "1 egg 2",
          discover_date: DateTime.now().subtract(Duration(days: 2)),
          responsible: "Admin",
          ring: null,
          last_modified: DateTime.now().subtract(Duration(days: 1)),
          status: EggStatus('intact'),
          measures: [m1]);
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg2.id)
          .set(egg2.toJson());
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();
      //expect to find the egg in firestore
      var eggObj = await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .get();
      expect(eggObj.exists, true);
      Egg newEgg = Egg.fromDocSnapshot(eggObj);
      expect(newEgg.id, "1 egg 1");
      expect(newEgg.status.toString(), "intact");
      expect(newEgg.measures.length, 2);
      expect(newEgg.measures[0].name, "note");
      expect(newEgg.measures[0].value, "");
      expect(newEgg.measures[1].name, "weight");
      expect(newEgg.measures[1].value, "");

      egg2 = Egg.fromDocSnapshot(await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg2.id)
          .get());
      expect(egg2.status.toString(), "intact");
      //check that the egg measure 1 value is empty
      expect(egg2.measures.length, 2);
      expect(egg2.measures[0].name, "note");
      expect(egg2.measures[0].value, "");
      expect(egg2.measures[1].name, "weight");
      expect(egg2.measures[1].value, "");
      expect(egg2.measures[1].required, true, reason: "required measure");

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text("Validation failed"), findsOneWidget);
    });

    testWidgets("will save nest when required measures are bypassed on egg",
        (WidgetTester tester) async {
      Egg egg2 = Egg(
          id: "1 egg 2",
          discover_date: DateTime.now().subtract(Duration(days: 2)),
          responsible: "Admin",
          ring: null,
          last_modified: DateTime.now().subtract(Duration(days: 1)),
          status: EggStatus('intact'),
          measures: [
            Measure.numeric(
                name: "weight",
                unit: "",
                required: true)
          ]);
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg2.id)
          .set(egg2.toJson());
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //enter text to the nest note
      Finder noteTextField = find.byType(TextField).at(1);
      await tester.enterText(noteTextField, "test note");
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text("save anyway"));
      await tester.pumpAndSettle();

      //expect to find the egg in firestore
      var eggObj = await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .get();
      expect(eggObj.exists, true);
      Egg newEgg = Egg.fromDocSnapshot(eggObj);
      expect(newEgg.id, "1 egg 1");
      expect(newEgg.status.toString(), "intact");
      expect(newEgg.measures.length, 2);
      expect(newEgg.measures[0].name, "note");
      expect(newEgg.measures[0].value, "");
      expect(newEgg.measures[1].name, "weight");
      expect(newEgg.measures[1].value, "");

      egg2 = Egg.fromDocSnapshot(await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg2.id)
          .get());
      expect(egg2.status.toString(), "intact");
      //check that the egg measure 1 value is empty
      expect(egg2.measures.length, 2);
      expect(egg2.measures[0].name, "note");
      expect(egg2.measures[0].value, "");
      expect(egg2.measures[1].name, "weight");
      expect(egg2.measures[1].value, "");

      expect(find.byType(AlertDialog), findsNothing);

      Nest nestObj = Nest.fromDocSnapshot(await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .get());
      expect(nestObj.measures[0].value, "test note");
    });
    testWidgets(
        "will save nest when egg cant be measured but has required measure",
        (WidgetTester tester) async {
      Egg egg2 = Egg(
          id: "1 egg 1",
          discover_date: DateTime.now().subtract(Duration(days: 2)),
          responsible: "Admin",
          ring: null,
          last_modified: DateTime.now().subtract(Duration(days: 1)),
          status: EggStatus('missing'),
          measures: [
            Measure.numeric(name: "weight", unit: "", required: true)
          ]);
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .set(egg2.toJson());

      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //enter text to the nest note
      Finder noteTextField = find.byType(TextField).at(1);
      await tester.enterText(noteTextField, "test note");
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);


      egg2 = Egg.fromDocSnapshot(await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg2.id)
          .get());
      expect(egg2.status.toString(), "missing");
      //check that the egg measure 1 value is empty
      expect(egg2.measures.length, 2);
      expect(egg2.measures[0].name, "note");
      expect(egg2.measures[0].value, "");
      expect(egg2.measures[1].name, "weight");
      expect(egg2.measures[1].value, "");

      expect(find.byType(AlertDialog), findsNothing);

      Nest nestObj = Nest.fromDocSnapshot(await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .get());
      expect(nestObj.measures[0].value, "test note");
    });
  });

  group("validate nest accuracy", () {
    setUp(() async {
      //reset the database
      nest.accuracy = "13.22m";
      await firestore.collection('recent').doc("nest").set({"id": "1"});
      await nest.save(firestore);
      egg.measures = [];
      //add egg to nest
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .set(egg.toJson());

      myApp = await getMyApp();
    });

    tearDown(() async {
      //delete all nest eggs
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .get()
          .then((value) {
        value.docs.forEach((element) {
          element.reference.delete();
        });
      });

      //delete nest
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .delete();
    });

    testWidgets("will raise an alertdialog for low accuracy",
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text("save anyway"));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      Nest nestObj = Nest.fromDocSnapshot(await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .get());
      expect(nestObj.accuracy, "13.22m");
    });

    testWidgets("will save nest when accuracy is OK when updated",
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      Nest nestObj = Nest.fromDocSnapshot(await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .get());
      expect(nestObj.accuracy, "3.20m");
    });
  });

  group("upload image", () {
    setUp(() async {
      //reset the database
      nest.accuracy = "3.22m";
      await firestore.collection('recent').doc("nest").set({"id": "1"});
      await nest.save(firestore);
      egg.measures = [];
      //add egg to nest
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .set(egg.toJson());

      myApp = await getMyApp();
    });

    tearDown(() async {
      //delete nest
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .delete();
    });

    testWidgets("will show image dialog", (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group("save undefined species", () {
    setUp(() async {
      //reset the database
      sharedPreferencesService.speciesList = LocalSpeciesList();
      nest.accuracy = "3.22m";
      nest.species = null;
      await firestore.collection('recent').doc("nest").set({"id": "1"});
      await nest.save(firestore);
      egg.measures = [];
      //add egg to nest
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .set(egg.toJson());

      myApp = await getMyApp();
    });

    tearDown(() async {
      //delete all nest eggs
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .get()
          .then((value) {
        value.docs.forEach((element) {
          element.reference.delete();
        });
      });

      //delete nest
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .delete();
    });

    testWidgets("will raise an alertdialog if species is missing",
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text("save anyway"));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      Nest nestObj = Nest.fromDocSnapshot(await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .get());
      expect(nestObj.species, '');
    });

    testWidgets("will allow saving when species is not in the list",
        (WidgetTester tester) async {
      nest.species = "undefined";
      await nest.save(firestore);
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //set species to undefined in SpeciesRawAutocomplete
          Finder speciesRawAutocompleteFinder = find.byType(
              SpeciesRawAutocomplete);
          expect(speciesRawAutocompleteFinder, findsOneWidget);

      // Find the TextField widget which is a descendant of the SpeciesRawAutocomplete widget
      Finder textFieldFinder = find.descendant(
        of: speciesRawAutocompleteFinder,
        matching: find.byType(TextField),
      );
      expect(textFieldFinder, findsOneWidget);

      TextField textField = tester.widget(textFieldFinder);
          expect(textField.controller?.text, 'undefined');

      Finder saveBtn = find.byKey(Key("saveButton"));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing,
              reason: "AlertDialog found although species should be set");
          Nest nestObj = Nest.fromDocSnapshot(await firestore
              .collection(nest.discover_date.year.toString())
              .doc(nest.id)
              .get());
          expect(nestObj.species, "undefined");
        });
  });

  group("experiment cleanup", () {
    setUp(() async {
      Experiment lingeringExperiment = Experiment(
        id: "exp-1",
        name: "Lingering Experiment",
        color: Colors.orange,
      );
      Nest nestWithExperiment = Nest(
        id: nest.id,
        coordinates: nest.coordinates,
        accuracy: nest.accuracy,
        last_modified: nest.last_modified,
        discover_date: nest.discover_date,
        first_egg: nest.first_egg,
        responsible: nest.responsible,
        species: nest.species,
        measures: [Measure.note()],
        experiments: [lingeringExperiment],
      );
      await firestore.collection('recent').doc("nest").set({"id": "1"});
      await nestWithExperiment.save(firestore);
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .set(egg.toJson());
      myApp = await getMyApp();
    });

    tearDown(() async {
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .get()
          .then((value) {
        value.docs.forEach((element) {
          element.reference.delete();
        });
      });
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .delete();
    });

    testWidgets("can remove lingering experiment from nest",
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      expect(find.text("Lingering Experiment"), findsOneWidget);

      await tester.longPress(find.byKey(Key("experimentTag_exp-1")));
      await tester.pumpAndSettle();

      expect(find.text("Remove experiment"), findsOneWidget);
      await tester.tap(find.text("Remove"));
      await tester.pumpAndSettle();

      expect(find.text("Lingering Experiment"), findsNothing);

      DocumentSnapshot nestDoc = await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .get();
      Map<String, dynamic> data = nestDoc.data() as Map<String, dynamic>;
      List<dynamic> experiments = data['experiments'] ?? [];
      expect(experiments.length, 0);
    });
  });
}
