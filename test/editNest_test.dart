import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/models/firestore/bird.dart';
import 'package:kakrarahu/models/firestore/egg.dart';
import 'package:kakrarahu/models/firestore/nest.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/screens/bird/editBird.dart';
import 'package:kakrarahu/screens/homepage.dart';
import 'package:kakrarahu/screens/nest/editEgg.dart';
import 'package:kakrarahu/screens/nest/editNest.dart';
import 'package:kakrarahu/screens/nest/findNest.dart';
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
    accuracy: "12.22m",
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
      status: "intact",
      measures: [Measure.note()]);

  setUpAll(() async {
    AuthService.instance = authService;
    LocationService.instance = locationAccuracy10;

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
            builder: (context) => MyHomePage(title: "Nest app"),
          );
        },
      ),
    );
  });
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
      expect(eggObj.status, "hatched");
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
      expect(eggObj.status, "hatched");
      expect(eggObj.discover_date, newBird.ringed_date);
    });
  });
}
