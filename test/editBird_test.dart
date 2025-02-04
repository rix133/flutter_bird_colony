import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/speciesRawAutocomplete.dart';
import 'package:flutter_bird_colony/models/eggStatus.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/models/firestore/egg.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_bird_colony/screens/bird/editBird.dart';
import 'package:flutter_bird_colony/screens/homepage.dart';
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
  final Nest masterNest = Nest(
    id: "1",
    coordinates: GeoPoint(0, 0),
    accuracy: "2.22m",
    last_modified: DateTime.now(),
    discover_date: DateTime.now(),
    responsible: "Admin",
    species: "test",
    measures: [Measure.note()],
  );
  final Egg masterEgg = Egg(
      id: "1 egg 1",
      discover_date: DateTime.now().subtract(Duration(days: 2)),
      responsible: "Admin",
      ring: null,
      last_modified: DateTime.now().subtract(Duration(days: 1)),
      status: EggStatus('intact'),
      measures: [Measure.note()]);

  final Egg masterEggEgg = Egg(
      id: "1 egg 2",
      discover_date: DateTime.now().subtract(Duration(days: 2)),
      responsible: "Admin",
      ring: "AA1236",
      last_modified: DateTime.now().subtract(Duration(days: 1)),
      status: EggStatus('hatched'),
      measures: [Measure.note(value: "test")]);

  final Egg masterChickEgg = Egg(
      id: "1 chick AA1235",
      discover_date: DateTime(1900),
      responsible: "Admin",
      ring: "AA1235",
      last_modified: DateTime.now().subtract(Duration(days: 32)),
      status: EggStatus('hatched'),
      measures: []);
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

  final Bird masterParent = Bird(
      ringed_date: DateTime.now().subtract(Duration(days: 360 * 3)),
      band: 'AA1111',
      ringed_as_chick: true,
      measures: [Measure.note(value: "test")],
      nest: "234",
      //3 years ago this was the nest
      nest_year: DateTime
          .now()
          .subtract(Duration(days: 360 * 3))
          .year,
      responsible: 'Admin',
      last_modified: DateTime.now().subtract(Duration(days: 360 * 3)),
      species: 'Common gull');

  final Bird masterChickChick = Bird(
      ringed_date: DateTime.now().subtract(Duration(days: 32)),
      band: 'AA1235',
      ringed_as_chick: true,
      measures: [Measure.note(value: "test")],
      nest: "1",
      nest_year: DateTime.now().year,
      responsible: 'Admin',
      last_modified: DateTime.now().subtract(Duration(days: 32)),
      species: 'Common gull');

  final Bird masterEggChick = Bird(
      ringed_date: DateTime.now().subtract(Duration(days: 32)),
      band: 'AA1236',
      ringed_as_chick: true,
      measures: [Measure.note(value: "test")],
      nest: "1",
      egg: "2",
      nest_year: DateTime.now().year,
      responsible: 'Admin',
      last_modified: DateTime.now().subtract(Duration(days: 32)),
      species: 'Common gull');

  setUpAll(() async {
    AuthService.instance = authService;
    LocationService.instance = locationAccuracy10;


    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});
  });

  getInitApp(Map<String, dynamic>? arguments) {
    return ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
        initialRoute: '/editBird',
        onGenerateRoute: (settings) {
          if (settings.name == '/editBird') {
            return MaterialPageRoute(
              builder: (context) =>
                  EditBird(
                    firestore: firestore,
                  ),
              settings: RouteSettings(
                arguments: arguments, // get initial nest from object
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

  group("Load Bird", () {
    late Egg egg;
    late Bird parent;
    late Nest nest;
    setUp(() async {
      parent = masterParent.copy();
      egg = masterEgg.copy();
      nest = masterNest.copy();
      //reset the database
      await firestore.collection('recent').doc("nest").set({"id": "1"});
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .set(nest.toJson());
      await firestore.collection("Birds").doc(parent.band).set(parent.toJson());
      //add egg to nest
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .set(egg.toJson());
      await firestore
          .collection('experiments')
          .doc(experiment.id)
          .set(experiment.toJson());
    });

    testWidgets("Will load edit bird without arguments",
        (WidgetTester tester) async {
      myApp = getInitApp(null);
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();
      expect(find.byType(EditBird), findsOneWidget);
    });

    testWidgets("Will load edit bird with nest and egg",
        (WidgetTester tester) async {
      myApp = getInitApp({"nest": nest, "egg": egg});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();
      expect(find.byType(EditBird), findsOneWidget);
    });

    testWidgets("Will load edit bird with nest and parent",
        (WidgetTester tester) async {
      myApp = getInitApp({"nest": nest, "bird": parent});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();
      expect(find.byType(EditBird), findsOneWidget);
    });

    testWidgets("Will load edit bird with nest only",
        (WidgetTester tester) async {
      myApp = getInitApp({"nest": nest});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();
      expect(find.byType(EditBird), findsOneWidget);
    });

    testWidgets("Will load edit bird with bird", (WidgetTester tester) async {
      myApp = getInitApp({"bird": parent});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();
      expect(find.byType(EditBird), findsOneWidget);
    });

    testWidgets("Will load nest default bird if cant find it from firestore",
        (WidgetTester tester) async {
      parent.band = "not in firestore";
      parent.id = null;
      myApp = getInitApp({"bird": parent, "nest": nest});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();
      expect(find.byType(EditBird), findsOneWidget);
    });

    testWidgets("Will load nest default bird without band",
        (WidgetTester tester) async {
      parent.band = "";
      myApp = getInitApp({"bird": parent, "nest": nest});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();
      expect(find.byType(EditBird), findsOneWidget);
    });

    testWidgets("Will load bird without band", (WidgetTester tester) async {
      parent.band = "";
      parent.id = null;
      myApp = getInitApp({"bird": parent});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();
      expect(find.byType(EditBird), findsOneWidget);
    });

    testWidgets("Will display metal band", (WidgetTester tester) async {
      myApp = getInitApp({"bird": parent});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      expect(find.text("Metal: AA1111"), findsOneWidget);
    });

    testWidgets("Will allow edit band on egg", (WidgetTester tester) async {
      myApp = getInitApp({"nest": nest, "egg": egg});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();
      //find by key band_letCntr
      expect(find.byKey(Key("band_letCntr")), findsOneWidget);

      //enter letters
      await tester.enterText(find.byKey(Key("band_letCntr")), "aa");
      await tester.pumpAndSettle();

      //find by key band_numCntr
      expect(find.byKey(Key("band_numCntr")), findsOneWidget);
      //enter numbers
      await tester.enterText(find.byKey(Key("band_numCntr")), "1235");
      await tester.pumpAndSettle();

      //save the bird
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();
      //expect to find the bird in firestore
      var bird = await firestore.collection("Birds").doc("AA1235").get();
      expect(bird.exists, true);
    });

    testWidgets("can change bird species", (WidgetTester tester) async {
      myApp = getInitApp({"egg": egg});
      await tester.pumpWidget(myApp);
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
      await tester.enterText(textFieldFinder, 'te');
      await tester.pumpAndSettle();

      //tap the first listtile
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      //expect the textfield to read "Arctic tern"
      expect(find.text("Arctic tern"), findsOneWidget);
    });
  });

  group("Bird Measures", () {
    late Bird parent;
    late Egg egg;
    late Nest nest;
    setUp(() async {
      sharedPreferencesService.setRecentBand("All", "AA1234");

      parent = masterParent.copy();
      egg = masterEgg.copy();
      nest = masterNest.copy();
      //reset the database
      await firestore.collection('recent').doc("nest").set({"id": "1"});
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .set(nest.toJson());
      await firestore.collection("Birds").doc(parent.band).set(parent.toJson());
      //add egg to nest
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .set(egg.toJson());
      await firestore
          .collection('experiments')
          .doc(experiment.id)
          .set(experiment.toJson());
    });

    testWidgets("Will show note measure after band input on chick",
        (WidgetTester tester) async {
      myApp = getInitApp({"nest": nest, "egg": egg});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //expect not to find text note
      expect(find.text("note"), findsNothing);

      //find next band button
      expect(find.text("AA1235"), findsOneWidget);
      await tester.tap(find.text("AA1235"));
      await tester.pumpAndSettle();

      expect(find.text("note"), findsOneWidget);
    });

    testWidgets("Will show chick weight measure after band input on chick",
        (WidgetTester tester) async {
      sharedPreferencesService.defaultMeasures = [
        Measure.note(),
        Measure.numeric(name: "weight", type: "chick")
      ];
      myApp = getInitApp({"nest": nest, "egg": egg});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //expect not to find text note
      expect(find.text("weight"), findsNothing);

      //find next band button
      expect(find.text("AA1235"), findsOneWidget);
      await tester.tap(find.text("AA1235"));
      await tester.pumpAndSettle();

      expect(find.text("weight"), findsOneWidget);
    });

    testWidgets("Won't show egg weight measure after band input on chick",
        (WidgetTester tester) async {
      sharedPreferencesService.defaultMeasures = [
        Measure.note(),
        Measure.numeric(name: "weight", type: "egg")
      ];
      myApp = getInitApp({"nest": nest, "egg": egg});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //expect not to find text note
      expect(find.text("weight"), findsNothing);

      //find next band button
      expect(find.byKey(Key("nextBandButton")), findsOneWidget);
      //check the next band is correct
      expect(find.text("AA1235"), findsOneWidget);
      await tester.tap(find.byKey(Key("nextBandButton")));
      await tester.pumpAndSettle();

      //expect not to find measure weight
      expect(find.text("weight"), findsNothing);
    });
  });

  group("Save Bird", () {
    late Bird parent;
    late Egg egg;
    late Nest nest;
    setUp(() async {
      sharedPreferencesService.setRecentBand("All", "AA1234");
      parent = masterParent.copy();
      egg = masterEgg.copy();
      nest = masterNest.copy();
      //reset the database
      await firestore.collection("Birds").get().then((value) {
        for (var doc in value.docs) {
          doc.reference.delete();
        }
      });

      await firestore.collection('recent').doc("nest").set({"id": "1"});
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .set(nest.toJson());
      await firestore.collection("Birds").doc(parent.band).set(parent.toJson());
      //add egg to nest
      await firestore
          .collection(DateTime.now().year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .set(egg.toJson());
      await firestore
          .collection('experiments')
          .doc(experiment.id)
          .set(experiment.toJson());
    });

    testWidgets("Will set next band on egg", (WidgetTester tester) async {
      String nextBand = "AA1235";
      var bird = await firestore.collection("Birds").doc(nextBand).get();
      expect(bird.exists, false, reason: "Next bird already exists");
      myApp = getInitApp({"nest": nest, "egg": egg});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //fnd tnext band button
      expect(find.text(nextBand), findsOneWidget);
      await tester.tap(find.text(nextBand));
      await tester.pumpAndSettle();

      //save the bird
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();
      //expect to find the bird in firestore
      bird = await firestore.collection("Birds").doc(nextBand).get();
      expect(bird.exists, true);
    });

    testWidgets("Will save next band to local storage",
        (WidgetTester tester) async {
      String nextBand = "AA1235";
      var bird = await firestore.collection("Birds").doc(nextBand).get();
      expect(bird.exists, false, reason: "Next bird already exists");
      myApp = getInitApp({"nest": nest, "egg": egg});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //fnd tnext band button
      expect(find.text(nextBand), findsOneWidget);
      await tester.tap(find.text(nextBand));
      await tester.pumpAndSettle();

      //save the bird
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      expect(sharedPreferencesService.getRecentMetalBand("All"), nextBand,
          reason: "Recent band not saved");
    });

    testWidgets("Will save color band on existing parent",
        (WidgetTester tester) async {
      parent.id = parent.band;
      myApp = getInitApp({"bird": parent});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      final finder = find.byWidgetPredicate((Widget widget) =>
          widget is InputDecorator &&
          widget.decoration.labelText == 'color ring');

      //print labels of all input decorators
      //for (var item in tester.allWidgets.whereType<InputDecorator>()) {
      //  print(item.decoration.labelText);
      //}

      expect(finder, findsOneWidget);

      await tester.enterText(finder, "A1b2");
      await tester.pumpAndSettle();

      //save the bird
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();
      //expect to find the bird in firestore
      var bird = await firestore.collection("Birds").doc(parent.band).get();
      expect(bird.exists, true);
      expect(bird.data()!['color_band'], "A1B2");
    });
    testWidgets("Will save color band on new parent",
        (WidgetTester tester) async {
      parent = masterParent.copy();
      parent.id = null;
      await firestore.collection("Birds").doc(parent.band).delete();
      myApp = getInitApp({"bird": parent});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //enter letters
      await tester.enterText(find.byKey(Key("band_letCntr")), "aa");
      await tester.pumpAndSettle();

      //find by key band_numCntr
      expect(find.byKey(Key("band_numCntr")), findsOneWidget);
      //enter numbers
      await tester.enterText(find.byKey(Key("band_numCntr")), "1234");
      await tester.pumpAndSettle();

      final finder = find.byWidgetPredicate((Widget widget) =>
          widget is InputDecorator &&
          widget.decoration.labelText == 'color ring');


      expect(finder, findsOneWidget);

      await tester.enterText(finder, "A1b2");
      await tester.pumpAndSettle();

      //save the bird
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      //expect to find the bird in firestore
      var bird = await firestore.collection("Birds").doc("AA1234").get();
      expect(bird.exists, true);
      expect(bird.data()!['color_band'], "A1B2");
    });

    testWidgets("Will save nest on new parent that exists after alert dialog",
        (WidgetTester tester) async {
      myApp = getInitApp({"nest": nest});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //enter letters
      await tester.enterText(find.byKey(Key("band_letCntr")), "aa");
      await tester.pumpAndSettle();

      //find by key band_numCntr
      expect(find.byKey(Key("band_numCntr")), findsOneWidget);
      //enter numbers
      await tester.enterText(find.byKey(Key("band_numCntr")), "1111");
      await tester.pumpAndSettle();

      //save the bird
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      //expect an AlertDialog
      expect(find.byType(AlertDialog), findsOneWidget);

      //tap the overwite button
      await tester.tap(find.text("Overwrite"));
      await tester.pumpAndSettle();

      //expect to find the bird in firestore
      var bird = await firestore.collection("Birds").doc("AA1111").get();
      expect(bird.exists, true);
      Bird parentObj = Bird.fromDocSnapshot(bird);
      expect(parentObj.nest, nest.id);
      expect(parentObj.nest_year, nest.discover_date.year);
    });

    testWidgets("Will update parent nest and nest year after alert dialog",
        (WidgetTester tester) async {
      myApp = getInitApp({"bird": parent});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();
      String year = DateTime.now().year.toString();

      final finder = find.byWidgetPredicate((Widget widget) =>
          widget is InputDecorator &&
          widget.decoration.labelText == 'nest ($year)');

      expect(finder, findsOneWidget);

      await tester.enterText(finder, "22");
      await tester.pumpAndSettle();

      //save the bird
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      //expect an AlertDialog
      expect(find.byType(AlertDialog), findsOneWidget);

      //tap the overwite button
      await tester.tap(find.text("Overwrite"));
      await tester.pumpAndSettle();

      //expect to find the bird in firestore
      var bird = await firestore.collection("Birds").doc(parent.band).get();
      expect(bird.exists, true);
      Bird parentObj = Bird.fromDocSnapshot(bird);
      expect(parentObj.nest, "22");
      expect(parentObj.nest_year, DateTime.now().year);
    });

    testWidgets(
        "Wont update parent nest and nest year after alert dialog if canceled",
        (WidgetTester tester) async {
      myApp = getInitApp({"bird": parent});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();
      String year = DateTime.now().year.toString();

      final finder = find.byWidgetPredicate((Widget widget) =>
          widget is InputDecorator &&
          widget.decoration.labelText == 'nest ($year)');

      expect(finder, findsOneWidget);

      await tester.enterText(finder, "22");
      await tester.pumpAndSettle();

      //save the bird
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      //expect an AlertDialog
      expect(find.byType(AlertDialog), findsOneWidget);

      //tap the cancel button
      await tester.tap(find.text("Cancel"));
      await tester.pumpAndSettle();

      //expect to find the bird in firestore
      var bird = await firestore.collection("Birds").doc(parent.band).get();
      expect(bird.exists, true);
      Bird parentObj = Bird.fromDocSnapshot(bird);
      expect(parentObj.nest, parent.nest);
      expect(parentObj.nest_year, parent.nest_year);
    });

    testWidgets("Won't save new parent if band exists",
        (WidgetTester tester) async {
      myApp = getInitApp({});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //enter letters
      await tester.enterText(find.byKey(Key("band_letCntr")), "aa");
      await tester.pumpAndSettle();

      //find by key band_numCntr
      expect(find.byKey(Key("band_numCntr")), findsOneWidget);
      //enter numbers
      await tester.enterText(find.byKey(Key("band_numCntr")), "1111");
      await tester.pumpAndSettle();

      //save the bird
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      //expect an AlertDialog
      expect(find.byType(AlertDialog), findsOneWidget);

      //expect to find the bird in firestore
      var bird = await firestore.collection("Birds").doc("AA1111").get();
      expect(bird.exists, true);
      // expect the bird to be unchanged
      Bird parentObj = Bird.fromDocSnapshot(bird);
      expect(parentObj.band, "AA1111");
      expect(parentObj.last_modified, parent.last_modified);
      expect(parentObj.responsible, parent.responsible);
    });

    testWidgets("will update color band on nest parent",
        (WidgetTester tester) async {
      parent.id = parent.band;
      parent.nest = nest.id;
      parent.nest_year = nest.discover_date.year;
      nest.parents = [parent];
      await parent.save(firestore, allowOverwrite: true);
      await nest.save(firestore);

      myApp = getInitApp({"bird": parent});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      final finder = find.byWidgetPredicate((Widget widget) =>
          widget is InputDecorator &&
          widget.decoration.labelText == 'color ring');

      expect(finder, findsOneWidget);

      await tester.enterText(finder, "A1b2");
      await tester.pumpAndSettle();

      //save the bird
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();
      //expect to find the bird in firestore
      var bird = await firestore.collection("Birds").doc(parent.band).get();
      expect(bird.exists, true);
      expect(bird.data()!['color_band'], "A1B2");
      Nest fsNest = await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .get()
          .then((value) => Nest.fromDocSnapshot(value));
      expect(fsNest.parents?.first.color_band, "A1B2");
    });

    testWidgets("will raise an alert dialog when overwriting an existing bird",
        (WidgetTester tester) async {
      myApp = getInitApp({"nest": nest, "egg": egg});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //find the letters and numbers inputs
      await tester.enterText(find.byKey(Key("band_letCntr")), "AA");
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key("band_numCntr")), "1111");
      await tester.pumpAndSettle();

      //save the bird
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      //expect to find the bird in firestore
      var bird = await firestore.collection("Birds").doc("AA1111").get();
      expect(bird.exists, true);
      //expect the bird to be unchanged
      Bird parentObj = Bird.fromDocSnapshot(bird);
      expect(parentObj.band, "AA1111");
      expect(parentObj.last_modified, parent.last_modified);
      expect(parentObj.responsible, parent.responsible);
    });
  });

  group("Delete Bird", () {
    late Egg egg;
    late Bird parent;
    late Nest nest;
    late Bird chickChick;
    late Bird eggChick;
    late Egg chickEgg;
    late Egg eggEgg;
    setUp(() async {
      parent = masterParent.copy();
      egg = masterEgg.copy();
      nest = masterNest.copy();
      chickChick = masterChickChick.copy();
      eggChick = masterEggChick.copy();
      chickEgg = masterChickEgg.copy();
      eggEgg = masterEggEgg.copy();
      parent.id = parent.band;
      parent.nest = nest.id;
      parent.nest_year = nest.discover_date.year;
      chickChick.id = chickChick.band;
      eggChick.id = eggChick.band;

      sharedPreferencesService.setRecentBand("All", "AA1234");

      nest.parents = [parent];
      //reset the database
      await firestore.collection('recent').doc("nest").set({"id": "1"});
      await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .set(nest.toJson());
      await firestore.collection("Birds").doc(parent.id).set(parent.toJson());
      await firestore
          .collection("Birds")
          .doc(chickChick.id)
          .set(chickChick.toJson());
      await firestore
          .collection("Birds")
          .doc(eggChick.id)
          .set(eggChick.toJson());
      //add eggs to nest
      await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .set(egg.toJson());
      await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(chickEgg.id)
          .set(chickEgg.toJson());
      await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(eggEgg.id)
          .set(eggEgg.toJson());
      await firestore
          .collection('experiments')
          .doc(experiment.id)
          .set(experiment.toJson());
    });
    testWidgets("can delete bird", (WidgetTester tester) async {
      myApp = getInitApp({"bird": parent});
      await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text("Removing item"), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    //expect to find the bird in firestore
      var bird = await firestore.collection("Birds").doc("AA1111").get();
      expect(bird.exists, false);
  });

    testWidgets("can delete chick bird artefacts from egg",
        (WidgetTester tester) async {
      chickChick = await firestore
          .collection("Birds")
          .doc(chickChick.band)
          .get()
          .then((value) => Bird.fromDocSnapshot(value));
      myApp = getInitApp({"bird": chickChick});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text("Removing item"), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      //expect to not find the bird in firestore
      var bird = await firestore.collection("Birds").doc(chickChick.band).get();
      expect(bird.exists, false);
      //expect the ring to be removed from the egg
      var egg = await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(chickEgg.id)
          .get();
      expect(egg.exists, false);
    });

    testWidgets("can delete egg bird artefacts from egg",
        (WidgetTester tester) async {
      eggChick = await firestore
          .collection("Birds")
          .doc(eggChick.band)
          .get()
          .then((value) => Bird.fromDocSnapshot(value));
      myApp = getInitApp({"bird": eggChick});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text("Removing item"), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      //expect to not find the bird in firestore
      var bird = await firestore.collection("Birds").doc(eggChick.band).get();
      expect(bird.exists, false);
      //expect the ring to be removed from the egg
      var egg = await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(eggEgg.id)
          .get();
      expect(egg.exists, true);
      expect(egg.data()!['ring'], null);
    });

    testWidgets("can delete parent bird artefacts from nest",
        (WidgetTester tester) async {
      parent = await firestore
          .collection("Birds")
          .doc(parent.band)
          .get()
          .then((value) => Bird.fromDocSnapshot(value));
      myApp = getInitApp({"bird": parent});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text("Removing item"), findsOneWidget);

      await tester.tap(find.text('Delete'));
          await tester.pumpAndSettle();

          //expect to not find the bird in firestore
          var bird = await firestore.collection("Birds").doc(parent.band).get();
          expect(bird.exists, false);
          //expect the Parent to be removed from the nest
          Nest fsNest = await firestore
              .collection(nest.discover_date.year.toString())
              .doc(nest.id)
              .get()
              .then((value) => Nest.fromDocSnapshot(value));
          expect(fsNest.parents?.length, 0);
        });
  });

  group("Change Bird Band", () {
    late Egg egg;
    late Bird parent;
    late Nest nest;
    late Bird chickChick;
    late Bird eggChick;
    late Egg chickEgg;
    late Egg eggEgg;
    setUp(() async {
      parent = masterParent.copy();
      egg = masterEgg.copy();
      nest = masterNest.copy();
      chickChick = masterChickChick.copy();
      eggChick = masterEggChick.copy();
      chickEgg = masterChickEgg.copy();
      eggEgg = masterEggEgg.copy();

      chickEgg.discover_date = chickChick.ringed_date;

      parent.id = parent.band;
      parent.nest = nest.id;
      parent.nest_year = nest.discover_date.year;
      chickChick.id = chickChick.band;
      eggChick.id = eggChick.band;

      sharedPreferencesService.setRecentBand("All", "AA1234");

      nest.parents = [parent];
      //reset the database
      await firestore.collection('recent').doc("nest").set({"id": "1"});
      await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .set(nest.toJson());
      await firestore.collection("Birds").doc(parent.id).set(parent.toJson());
      await firestore
          .collection("Birds")
          .doc(chickChick.id)
          .set(chickChick.toJson());
      await firestore
          .collection("Birds")
          .doc(eggChick.id)
          .set(eggChick.toJson());
      //add eggs to nest
      await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .set(egg.toJson());
      await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(chickEgg.id)
          .set(chickEgg.toJson());
      await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(eggEgg.id)
          .set(eggEgg.toJson());
      await firestore
          .collection('experiments')
          .doc(experiment.id)
          .set(experiment.toJson());
    });

    tearDown(() async {
      await firestore.collection("Birds").get().then((value) {
        for (var doc in value.docs) {
          doc.reference.delete();
        }
      });
      //delete all eggs from nest 1
      await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .collection("egg")
          .get()
          .then((value) {
        for (var doc in value.docs) {
          doc.reference.delete();
        }
      });
      //delete all nests
      await firestore
          .collection(nest.discover_date.year.toString())
          .get()
          .then((value) {
        for (var doc in value.docs) {
          doc.reference.delete();
        }
      });
    });

    testWidgets(
        "when a bird band is changed old bird is deleted and new bird is saved",
        (WidgetTester tester) async {
      parent = await firestore
          .collection("Birds")
          .doc(parent.band)
          .get()
          .then((value) => Bird.fromDocSnapshot(value));
      myApp = getInitApp({"bird": parent});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //find the band text band and long press it
      await tester.longPress(find.text("Metal: ${parent.band}"));
      await tester.pumpAndSettle();

      //expect an alert dialog
      expect(find.byType(AlertDialog), findsOneWidget);

      //find the letters and numbers inputs
      await tester.enterText(find.byKey(Key("band_letCntr")), "bb");
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key("band_numCntr")), "1235");
      await tester.pumpAndSettle();

      //find the save button
      await tester.tap(find.byKey(Key("changeBandButton")));
      await tester.pumpAndSettle();

      //expect the old bird to be deleted
      var bird = await firestore.collection("Birds").doc(parent.band).get();
      expect(bird.exists, false);
      //expect the new bird to be saved
      bird = await firestore.collection("Birds").doc("BB1235").get();
      expect(bird.exists, true);

      //expect that all other fields are unchanged
      Bird newBird = Bird.fromDocSnapshot(bird);
      expect(newBird.band, "BB1235");
      expect(newBird.ringed_date, parent.ringed_date,
          reason: "ringed date should not change");
      expect(newBird.ringed_as_chick, parent.ringed_as_chick);
      expect(newBird.measures.length, parent.measures.length);
      //chek that the value for each measures is the same
      for (var i = 0; i < newBird.measures.length; i++) {
        expect(newBird.measures[i].value, parent.measures[i].value);
      }
      expect(newBird.nest, parent.nest);
      expect(newBird.nest_year, parent.nest_year);
      expect(newBird.responsible, isNot(parent.responsible),
          reason: "responsible should change");
      expect(newBird.last_modified, isNot(parent.last_modified));
      expect(newBird.species, parent.species);
      expect(newBird.color_band, parent.color_band,
          reason: "color band should not change");
      expect(newBird.egg, parent.egg);
      expect(newBird.age, parent.age);
      expect(newBird.experiments?.length, parent.experiments?.length);
    });

    testWidgets(
        "when a bird band is changed to existing bird no change happens",
        (WidgetTester tester) async {
      parent = await firestore
          .collection("Birds")
          .doc(parent.band)
          .get()
          .then((value) => Bird.fromDocSnapshot(value));

      chickChick = await firestore
          .collection("Birds")
          .doc(chickChick.band)
          .get()
          .then((value) => Bird.fromDocSnapshot(value));
      myApp = getInitApp({"bird": parent});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //find the band text band and long press it
      await tester.longPress(find.text("Metal: ${parent.band}"));
      await tester.pumpAndSettle();

      //expect an alert dialog
      expect(find.byType(AlertDialog), findsOneWidget);

      //find the letters and numbers inputs
      await tester.enterText(find.byKey(Key("band_letCntr")), "aa");
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key("band_numCntr")), "1235");
      await tester.pumpAndSettle();

      //find the save button
      await tester.tap(find.byKey(Key("changeBandButton")));
      await tester.pumpAndSettle();

      //expect the old bird not to be deleted
      var bird = await firestore.collection("Birds").doc(parent.band).get();
      expect(bird.exists, true);
      //expect the exiting bird is not overwritten
      bird = await firestore.collection("Birds").doc("AA1235").get();
      expect(bird.exists, true);

      //expect that all other fields are unchanged
      Bird newBird = Bird.fromDocSnapshot(bird);
      expect(newBird.band, chickChick.band);
      expect(newBird.ringed_date, chickChick.ringed_date,
          reason: "ringed date should not change");
      expect(newBird.ringed_as_chick, chickChick.ringed_as_chick);
      expect(newBird.measures.length, chickChick.measures.length);
      //chek that the value for each measures is the same
      for (var i = 0; i < newBird.measures.length; i++) {
        expect(newBird.measures[i].value, chickChick.measures[i].value);
      }
      expect(newBird.nest, chickChick.nest);
      expect(newBird.nest_year, chickChick.nest_year);
      expect(newBird.responsible, chickChick.responsible);
      expect(newBird.last_modified, chickChick.last_modified);
      expect(newBird.species, chickChick.species);
      expect(newBird.color_band, chickChick.color_band,
          reason: "color band should not change");
    });

    testWidgets(
        "when a bird band is changed and it is a parent on a nest the nest parents are updated",
        (WidgetTester tester) async {
      parent = await firestore
          .collection("Birds")
          .doc(parent.band)
          .get()
          .then((value) => Bird.fromDocSnapshot(value));
      myApp = getInitApp({"bird": parent});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //find the band text band and long press it
      await tester.longPress(find.text("Metal: ${parent.band}"));
      await tester.pumpAndSettle();

      //expect an alert dialog
      expect(find.byType(AlertDialog), findsOneWidget);

      //find the letters and numbers inputs
      await tester.enterText(find.byKey(Key("band_letCntr")), "bb");
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key("band_numCntr")), "1235");
      await tester.pumpAndSettle();

      //find the save button
      await tester.tap(find.byKey(Key("changeBandButton")));
      await tester.pumpAndSettle();

      //expect the old bird to be deleted
      var bird = await firestore.collection("Birds").doc(parent.band).get();
      expect(bird.exists, false);
      //expect the new bird to be saved
      bird = await firestore.collection("Birds").doc("BB1235").get();
      expect(bird.exists, true);

      Nest fsNest = await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .get()
          .then((value) => Nest.fromDocSnapshot(value));
      expect(fsNest.parents?.first.band, "BB1235");
    });

    testWidgets(
        "when a bird band is changed and it is a chick on a nest the nest chick egg is replaced",
        (WidgetTester tester) async {
      chickChick = await firestore
          .collection("Birds")
          .doc(chickChick.band)
          .get()
          .then((value) => Bird.fromDocSnapshot(value));

      myApp = getInitApp({"bird": chickChick});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //find the band text band and long press it
      await tester.longPress(find.text("Metal: AA1235"));
      await tester.pumpAndSettle();

      //expect an alert dialog
      expect(find.byType(AlertDialog), findsOneWidget);

      //find the letters and numbers inputs
      await tester.enterText(find.byKey(Key("band_letCntr")), "bb");
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key("band_numCntr")), "1235");
      await tester.pumpAndSettle();

      //find the save button
      await tester.tap(find.byKey(Key("changeBandButton")));
      await tester.pumpAndSettle();

      //expect the old bird to be deleted
      var bird = await firestore.collection("Birds").doc("AA1235").get();
      expect(bird.exists, false);
      //expect the new bird to be saved
      bird = await firestore.collection("Birds").doc("BB1235").get();
      expect(bird.exists, true);

      var oldEgg = await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(chickEgg.id)
          .get();
      expect(oldEgg.exists, false);
      var newEgg = await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc("1 chick BB1235")
          .get();
      expect(newEgg.exists, true,
          reason: "new egg with correct id should exist");
      //expect the egg fields to be unchanged
      Egg newEggObj = Egg.fromDocSnapshot(newEgg);
      expect(newEggObj.discover_date, chickEgg.discover_date,
          reason: "discover date should not change");
      expect(newEggObj.responsible, isNot(chickEgg.responsible));
      expect(newEggObj.ring, "BB1235", reason: "ring should change");
      //last modified should change
      expect(newEggObj.last_modified, isNot(chickEgg.last_modified),
          reason: "last modified should change");
      expect(newEggObj.status.toString(), chickEgg.status.toString(),
          reason: "status should not change");
      expect(newEggObj.measures.length, chickEgg.measures.length,
          reason: "measures should not change");
      //check that the value for each measures is the same
      for (var i = 0; i < newEggObj.measures.length; i++) {
        expect(newEggObj.measures[i].value, chickEgg.measures[i].value);
      }
    });

    testWidgets(
        "when a bird band is changed and it is a ringed egg on a nest the nest egg ring is updated",
        (WidgetTester tester) async {
      eggChick = await firestore
          .collection("Birds")
          .doc(eggChick.band)
          .get()
          .then((value) => Bird.fromDocSnapshot(value));
      myApp = getInitApp({"bird": eggChick});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //find the band text band and long press it
      await tester.longPress(find.text("Metal: AA1236"));
      await tester.pumpAndSettle();

      //expect an alert dialog
      expect(find.byType(AlertDialog), findsOneWidget);

      //find the letters and numbers inputs
      await tester.enterText(find.byKey(Key("band_letCntr")), "bb");
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key("band_numCntr")), "1236");
      await tester.pumpAndSettle();

      //find the save button
      await tester.tap(find.byKey(Key("changeBandButton")));
      await tester.pumpAndSettle();

      //expect the old bird to be deleted
      var bird = await firestore.collection("Birds").doc("AA1236").get();
      expect(bird.exists, false);
      //expect the new bird to be saved
      bird = await firestore.collection("Birds").doc("BB1236").get();
      expect(bird.exists, true);

      var oldEgg = await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(eggEgg.id)
          .get();
      expect(oldEgg.exists, true);
      //expect the egg fields to be unchanged expect for ring and last modified
      Egg newEggObj = Egg.fromDocSnapshot(oldEgg);
      expect(newEggObj.discover_date, eggEgg.discover_date,
          reason: "discover date should not change");
      expect(newEggObj.responsible, isNot(eggEgg.responsible));
      expect(newEggObj.ring, "BB1236", reason: "ring should change");
      //last modified should change
      expect(newEggObj.last_modified, isNot(eggEgg.last_modified),
          reason: "last modified should change");
      expect(newEggObj.status.toString(), eggEgg.status.toString(),
          reason: "status should not change");
      expect(newEggObj.measures.length, eggEgg.measures.length,
          reason: "measures should not change");
      //check that the value for each measures is the same
      for (var i = 0; i < newEggObj.measures.length; i++) {
        expect(newEggObj.measures[i].value, eggEgg.measures[i].value);
      }
    });
  });

  group("Edit Bird", () {
    late Egg egg;
    late Bird parent;
    late Nest nest;
    late Bird chickChick;
    late Bird eggChick;
    late Egg chickEgg;
    late Egg eggEgg;
    setUp(() async {
      parent = masterParent.copy();
      egg = masterEgg.copy();
      nest = masterNest.copy();
      chickChick = masterChickChick.copy();
      eggChick = masterEggChick.copy();
      chickEgg = masterChickEgg.copy();
      eggEgg = masterEggEgg.copy();

      chickEgg.discover_date = chickChick.ringed_date;

      sharedPreferencesService.setRecentBand("All", "AA1234");

      parent.id = parent.band;
      parent.nest = nest.id;
      parent.nest_year = nest.discover_date.year;
      chickChick.id = chickChick.band;
      eggChick.id = eggChick.band;

      nest.parents = [parent];
      //reset the database
      await firestore.collection('recent').doc("nest").set({"id": "1"});
      await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .set(nest.toJson());
      await firestore.collection("Birds").doc(parent.id).set(parent.toJson());
      await firestore
          .collection("Birds")
          .doc(chickChick.id)
          .set(chickChick.toJson());
      await firestore
          .collection("Birds")
          .doc(eggChick.id)
          .set(eggChick.toJson());
      //add eggs to nest
      await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(egg.id)
          .set(egg.toJson());
      await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(chickEgg.id)
          .set(chickEgg.toJson());
      await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .collection("egg")
          .doc(eggEgg.id)
          .set(eggEgg.toJson());
      await firestore
          .collection('experiments')
          .doc(experiment.id)
          .set(experiment.toJson());
    });

    tearDown(() async {
      await firestore.collection("Birds").get().then((value) {
        for (var doc in value.docs) {
          doc.reference.delete();
        }
      });
      //delete all eggs from nest 1
      await firestore
          .collection(nest.discover_date.year.toString())
          .doc(nest.id)
          .collection("egg")
          .get()
          .then((value) {
        for (var doc in value.docs) {
          doc.reference.delete();
        }
      });
      //delete all nests
      await firestore
          .collection(nest.discover_date.year.toString())
          .get()
          .then((value) {
        for (var doc in value.docs) {
          doc.reference.delete();
        }
      });
    });

    testWidgets(
        "when a note is added to bird it is saved with default settings",
        (WidgetTester tester) async {
      chickChick = await firestore
          .collection("Birds")
          .doc(eggChick.band)
          .get()
          .then((value) => Bird.fromDocSnapshot(value));
      myApp = getInitApp({"bird": chickChick});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //for(Element e in find.byType(Text).evaluate()){
      //     print((e.widget as Text).data);
      // }

      expect(find.text("Metal: AA1236"), findsOneWidget);

      //press the add note button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      //find the note widget and insert a note
      Finder noteFinder = find.byWidgetPredicate((Widget widget) =>
          widget is InputDecorator && widget.decoration.labelText == 'note');

      expect(noteFinder, findsOneWidget, reason: "note input not found");

      await tester.enterText(noteFinder, "dead");

      //find the save button
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      //expect the bird to be still there
      var bird = await firestore.collection("Birds").doc(chickChick.band).get();
      expect(bird.exists, true);
      //add note measure to chickChick
      chickChick.measures.add(Measure.note(value: "dead"));

      //expect that all other fields are unchanged
      Bird newBird = Bird.fromDocSnapshot(bird);
      expect(newBird.band, "AA1236");
      expect(newBird.ringed_date, chickChick.ringed_date,
          reason: "ringed date should not change");
      expect(newBird.ringed_as_chick, chickChick.ringed_as_chick);
      expect(newBird.measures.length, chickChick.measures.length);
      //chek that the value for each measures is the same
      for (var i = 0; i < newBird.measures.length; i++) {
        expect(newBird.measures[i].value, chickChick.measures[i].value);
      }
      expect(newBird.nest, chickChick.nest);
      expect(newBird.nest_year, chickChick.nest_year);
      expect(newBird.responsible, isNot(chickChick.responsible),
          reason: "responsible should change");
      expect(newBird.last_modified, isNot(chickChick.last_modified));
      expect(newBird.species, chickChick.species);
      expect(newBird.color_band, chickChick.color_band,
          reason: "color band should not change");
      expect(newBird.egg, chickChick.egg);
      expect(newBird.age, chickChick.age);
      expect(newBird.experiments?.length, chickChick.experiments?.length);
    });

    testWidgets("when a note is added to bird next band is not changed",
        (WidgetTester tester) async {
      chickChick = await firestore
          .collection("Birds")
          .doc(eggChick.band)
          .get()
          .then((value) => Bird.fromDocSnapshot(value));
      //set the current next band
      String nextBand = "AA1";
      sharedPreferencesService.setRecentBand(parent.species ?? "", nextBand);
      myApp = getInitApp({"bird": chickChick});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      expect(find.text("Metal: AA1236"), findsOneWidget);

      //press the add note button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      //find the note widget and insert a note
      Finder noteFinder = find.byWidgetPredicate((Widget widget) =>
          widget is InputDecorator && widget.decoration.labelText == 'note');

      expect(noteFinder, findsOneWidget, reason: "note input not found");

      await tester.enterText(noteFinder, "dead");

      //find the save button
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      //expect no next band change
      expect(
          sharedPreferencesService.getRecentMetalBand(chickChick.species ?? ""),
          nextBand,
          reason: "next band should not change on update");
    });

    testWidgets(
        "when a note is added to bird it is saved with auto assign parent next bands",
        (WidgetTester tester) async {
      parent = await firestore
          .collection("Birds")
          .doc(parent.band)
          .get()
          .then((value) => Bird.fromDocSnapshot(value));

      sharedPreferencesService.autoNextBandParent = true;
      sharedPreferencesService.setRecentBand(parent.species ?? "", "TT1");
      myApp = getInitApp({"bird": parent});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //check that bird TT2 deos not exist
      var bird = await firestore.collection("Birds").doc("TT2").get();
      expect(bird.exists, false);

      expect(sharedPreferencesService.getRecentMetalBand(parent.species ?? ""),
          "TT1");
      expect(find.text("Metal: ${parent.band}"), findsOneWidget);

      //press the add note button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      //find the note widget and insert a note
      Finder noteFinder = find.byWidgetPredicate((Widget widget) =>
          widget is InputDecorator && widget.decoration.labelText == 'note');

      expect(noteFinder, findsOneWidget, reason: "note input not found");

      await tester.enterText(noteFinder, "dead");

      //find the save button
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      //expect there is no bird with the new band
      bird = await firestore.collection("Birds").doc("TT2").get();
      expect(bird.exists, false, reason: "new band should not exist");

      //expect the original bird to be still there
      bird = await firestore.collection("Birds").doc(parent.band).get();
      expect(bird.exists, true, reason: "original bird should exist");
      //add note measure to chickChick
      parent.measures.add(Measure.note(value: "dead"));

      //expect that all other fields are unchanged
      Bird newBird = Bird.fromDocSnapshot(bird);
      expect(newBird.band, parent.band);
      expect(newBird.ringed_date, parent.ringed_date,
          reason: "ringed date should not change");
      expect(newBird.ringed_as_chick, parent.ringed_as_chick);
      expect(newBird.measures.length, parent.measures.length);
      //chek that the value for each measures is the same
      for (var i = 0; i < newBird.measures.length; i++) {
        expect(newBird.measures[i].value, parent.measures[i].value);
      }
      expect(newBird.nest, parent.nest);
      expect(newBird.nest_year, parent.nest_year);
      expect(newBird.responsible, isNot(parent.responsible),
          reason: "responsible should change");
      expect(newBird.last_modified, isNot(parent.last_modified));
      expect(newBird.species, parent.species);
      expect(newBird.color_band, parent.color_band,
          reason: "color band should not change");
      expect(newBird.egg, parent.egg);
      expect(newBird.age, parent.age);
      expect(newBird.experiments?.length, parent.experiments?.length);
    });

    testWidgets(
        "when a note is added to bird it is saved with auto assign chick next bands",
        (WidgetTester tester) async {
      chickChick = await firestore
          .collection("Birds")
          .doc(chickChick.band)
          .get()
          .then((value) => Bird.fromDocSnapshot(value));

      sharedPreferencesService.autoNextBand = true;
      sharedPreferencesService.setRecentBand(chickChick.species ?? "", "TT1");
      myApp = getInitApp({"bird": chickChick});
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      //for(Element e in find.byType(Text).evaluate()){
      //     print((e.widget as Text).data);
      // }
      //check that bird TT2 deos not exist
      var bird = await firestore.collection("Birds").doc("TT2").get();
      expect(bird.exists, false);

      expect(
          sharedPreferencesService.getRecentMetalBand(chickChick.species ?? ""),
          "TT1");
      expect(find.text("Metal: ${chickChick.band}"), findsOneWidget);

      //press the add note button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      //find the note widget and insert a note
      Finder noteFinder = find.byWidgetPredicate((Widget widget) =>
          widget is InputDecorator && widget.decoration.labelText == 'note');

      expect(noteFinder, findsOneWidget, reason: "note input not found");

      await tester.enterText(noteFinder, "dead");

      //find the save button
      await tester.tap(find.byKey(Key("saveButton")));
      await tester.pumpAndSettle();

      //expect there is no bird with the new band
      bird = await firestore.collection("Birds").doc("TT2").get();
      expect(bird.exists, false, reason: "new band should not exist");

      //expect the original bird to be still there
      bird = await firestore.collection("Birds").doc(chickChick.band).get();
      expect(bird.exists, true, reason: "original bird should exist");
      //add note measure to chickChick
      chickChick.measures.add(Measure.note(value: "dead"));

      //expect that all other fields are unchanged
      Bird newBird = Bird.fromDocSnapshot(bird);
      expect(newBird.band, chickChick.band);
      expect(newBird.ringed_date, chickChick.ringed_date,
          reason: "ringed date should not change");
      expect(newBird.ringed_as_chick, chickChick.ringed_as_chick);
      expect(newBird.measures.length, chickChick.measures.length);
      //chek that the value for each measures is the same
      for (var i = 0; i < newBird.measures.length; i++) {
        expect(newBird.measures[i].value, chickChick.measures[i].value);
      }
      expect(newBird.nest, chickChick.nest);
      expect(newBird.nest_year, chickChick.nest_year);
      expect(newBird.responsible, isNot(chickChick.responsible),
          reason: "responsible should change");
      expect(newBird.last_modified, isNot(chickChick.last_modified));
      expect(newBird.species, chickChick.species);
      expect(newBird.color_band, chickChick.color_band,
          reason: "color band should not change");
      expect(newBird.egg, chickChick.egg);
      expect(newBird.age, chickChick.age);
      expect(newBird.experiments?.length, chickChick.experiments?.length);
    });
  });
}