import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/models/firestore/bird.dart';
import 'package:kakrarahu/models/firestore/egg.dart';
import 'package:kakrarahu/models/firestore/experiment.dart';

import 'package:kakrarahu/screens/homepage.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/models/firestore/nest.dart';
import 'package:kakrarahu/screens/nest/editNest.dart';
import 'package:kakrarahu/screens/nest/listNests.dart';
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
    last_modified: DateTime.now().subtract(Duration(days: 1)),
    discover_date: DateTime.now().subtract(Duration(days: 1)),
    responsible: "Admin",
    species: "Common gull",
    measures: [Measure.note()],
  );

  final Nest nest2 = Nest(
    id: "2",
    coordinates: GeoPoint(0, 0),
    accuracy: "12.22m",
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
    await firestore.collection(nest1.discover_date.year.toString()).doc(nest1.id).set(nest1.toJson());
    await firestore.collection(nest2.discover_date.year.toString()).doc(nest2.id).set(nest2.toJson());
    await firestore.collection(nest3.discover_date.year.toString()).doc(nest3.id).set(nest3.toJson());

    await firestore.collection("Birds").doc(parent.band).set(parent.toJson());
    await firestore.collection("Birds").doc(chick.band).set(chick.toJson());
    //add egg to nest
    await firestore.collection(DateTime
        .now()
        .year
        .toString()).doc(nest1.id).collection("egg").doc(egg.id).set(
        egg.toJson());
    await firestore.collection('experiments').doc(experiment.id).set(
        experiment.toJson());

    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});


    myApp = ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
          initialRoute: '/listNests',
          routes: {
            '/': (context) => MyHomePage(title: "Nest app"),
            '/listNests': (context) => ListNests(firestore: firestore),
            '/editNest': (context) => EditNest(firestore: firestore),
          }
      ),
    );


  });

  testWidgets(
      "Will load the list of nests from this year and display them in a list",  (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //print all listtiles titles
    //print(find.byType(ListTile).evaluate().toList().map((e) => (e.widget as ListTile).title.toString()).toList());

    //check if the list of birds is displayed
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets(
      "Will load the list of nests from 2023 and display them in a list",  (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();
      //find the filter button
      await tester.tap(find.byIcon(Icons.filter_alt));
      await tester.pumpAndSettle();
      //find the year input dropdown
      await tester.tap(find.text(DateTime.now().year.toString()));
      await tester.pumpAndSettle();
        //tap the 2023 year  option
      await tester.tap(find.text("2023"));
      await tester.pumpAndSettle();

      //check if the list of birds is displayed
      expect(find.byType(ListTile), findsNWidgets(1));

  });
  testWidgets(
      "Will load the list of nests from 2022 and display them in a list",  (WidgetTester tester) async {
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
    expect(find.byType(ListTile), findsNWidgets(0));

  });
}