import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/models/firestore/bird.dart';
import 'package:kakrarahu/models/firestore/egg.dart';
import 'package:kakrarahu/models/firestore/experiment.dart';
import 'package:kakrarahu/models/firestore/firestoreItem.dart';
import 'package:kakrarahu/models/firestore/nest.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/screens/bird/editBird.dart';
import 'package:kakrarahu/screens/homepage.dart';
import 'package:kakrarahu/screens/nest/editEgg.dart';
import 'package:kakrarahu/screens/nest/editNest.dart';
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
  final Measure m = Measure(
    name: 'weight',
    value: '1',
    unit: '',
    type: 'chick',
    isNumber: true,
    repeated: true,
    modified: DateTime.now(),
  );
  final Egg egg = Egg(
      id: "1 egg 1",
      discover_date: DateTime.now().subtract(Duration(days: 20)),
      responsible: "Admin",
      ring: "AA1234",
      last_modified: DateTime.now().subtract(Duration(days: 3)),
      status: "hatched",
      measures: []);
  final Experiment experiment = Experiment(
    id: "1",
    name: "New Experiment",
    description: "Test experiment",
    last_modified: DateTime.now(),
    created: DateTime.now(),
    year: DateTime.now().year,
    responsible: "Admin",
    measures: [Measure.empty(m)],
  );

  late Bird chick;
  late Nest nest;

  setUpAll(() async {
    AuthService.instance = authService;
    LocationService.instance = locationAccuracy10;
    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});
  });

  getInitApp(String initRoute, FirestoreItem? arg) {
    return ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
        initialRoute: initRoute,
        onGenerateRoute: (settings) {
          if (settings.name == '/editNest') {
            return MaterialPageRoute(
              builder: (context) => EditNest(
                firestore: firestore,
              ),
              settings: RouteSettings(
                arguments: {'nest': arg}, // get initial nest from object
              ),
            );
          } else if (settings.name == '/editEgg') {
            return MaterialPageRoute(
              builder: (context) => EditEgg(
                firestore: firestore,
              ),
              settings: settings,
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
  }

  setUp(() async {
    chick = Bird(
        id: "AA1234",
        ringed_date: DateTime.now().subtract(Duration(days: 3)),
        band: 'AA1234',
        ringed_as_chick: true,
        measures: [],
        experiments: [experiment],
        egg: "1",
        nest: "1",
        nest_year: DateTime.now().year,
        responsible: 'Admin',
        last_modified: DateTime.now().subtract(Duration(days: 3)),
        species: 'Common gull');
    nest = Nest(
      id: "1",
      coordinates: GeoPoint(0, 0),
      accuracy: "12.22m",
      last_modified: DateTime.now(),
      discover_date: DateTime.now(),
      responsible: "Admin",
      species: "Common gull",
      measures: [],
      experiments: [experiment],
    );

    //reset the database
    await firestore.collection('recent').doc("nest").set({"id": "1"});
    await firestore
        .collection(DateTime.now().year.toString())
        .doc(nest.id)
        .set(nest.toJson());
    await firestore.collection("Birds").doc(chick.band).set(chick.toJson());
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

  testWidgets("will navigate to bird if hatched egg is long pressed",
      (WidgetTester tester) async {
    myApp = getInitApp('/editNest', nest);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    await tester.longPress(find.text("Egg 1 hatched/AA1234 20 days old"));
    await tester.pumpAndSettle();
    expect(find.byType(EditBird), findsOneWidget);
  });

  testWidgets("will navigate to egg if egg is tapped",
      (WidgetTester tester) async {
    myApp = getInitApp('/editNest', nest);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    await tester.tap(find.text("Egg 1 hatched/AA1234 20 days old"));
    await tester.pumpAndSettle();
    expect(find.byType(EditEgg), findsOneWidget);
  });

  testWidgets("will navigate to banded bird if hatched egg is long pressed",
      (WidgetTester tester) async {
    myApp = getInitApp('/editNest', nest);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    await tester.longPress(find.text("Egg 1 hatched/AA1234 20 days old"));
    await tester.pumpAndSettle();
    expect(find.byType(EditBird), findsOneWidget);
    for (Element i in find.byType(Text).evaluate()) {
      print((i.widget as Text).data);
    }
    expect(find.text("Metal: AA1234"), findsOneWidget);
  });

  testWidgets(
      "will display experiment measure on banded bird if hatched egg is long pressed",
      (WidgetTester tester) async {
    myApp = getInitApp('/editNest', nest);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    await tester.longPress(find.text("Egg 1 hatched/AA1234 20 days old"));
    await tester.pumpAndSettle();
    expect(find.byType(EditBird), findsOneWidget);
    expect(find.text("Metal: AA1234"), findsOneWidget);
    expect(find.text("weight"), findsOneWidget);
  });
}
