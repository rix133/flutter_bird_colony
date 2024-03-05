import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/models/firestore/bird.dart';
import 'package:kakrarahu/models/firestore/egg.dart';
import 'package:kakrarahu/models/firestore/experiment.dart';
import 'package:kakrarahu/screens/bird/editBird.dart';

import 'package:kakrarahu/screens/homepage.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/models/firestore/nest.dart';
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
      status: "intact",
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
      ringed_date: DateTime.now().subtract(Duration(days: 360 * 3)),
      band: 'AA1234',
      ringed_as_chick: true,
      measures: [Measure.note()],
      nest: "234",
      //3 years ago this was the nest
      nest_year: DateTime
          .now()
          .subtract(Duration(days: 360 * 3))
          .year,
      responsible: 'Admin',
      last_modified: DateTime.now().subtract(Duration(days: 360 * 3)),
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

  setUp(() async {
    //reset the database
    await firestore.collection('recent').doc("nest").set({"id": "1"});
    await firestore.collection(DateTime
        .now()
        .year
        .toString()).doc(nest.id).set(nest.toJson());
    await firestore.collection("Birds").doc(parent.band).set(parent.toJson());
    //add egg to nest
    await firestore.collection(DateTime
        .now()
        .year
        .toString()).doc(nest.id).collection("egg").doc(egg.id).set(
        egg.toJson());
    await firestore.collection('experiments').doc(experiment.id).set(
        experiment.toJson());
  });

  testWidgets(
      "Will load edit bird without arguments", (WidgetTester tester) async {
    myApp = getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    expect(find.byType(EditBird), findsOneWidget);
  });

  testWidgets(
      "Will load edit bird with nest and egg", (WidgetTester tester) async {
    myApp = getInitApp({"nest": nest, "egg": egg});
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
}