import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_bird_colony/screens/bird/editBird.dart';
import 'package:flutter_bird_colony/screens/bird/listBirds.dart';
import 'package:flutter_bird_colony/screens/homepage.dart';
import 'package:flutter_bird_colony/services/authService.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/mockAuthService.dart';
import 'mocks/mockSharedPreferencesService.dart';
import 'testApp.dart';

void main() {
  final authService = MockAuthService();
  final sharedPreferencesService = MockSharedPreferencesService();
  final firestore = FakeFirebaseFirestore();

  late TestApp myApp;
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
  final Measure m2 = Measure(
    name: 'identity',
    value: '',
    unit: '',
    type: 'chick',
    isNumber: true,
    repeated: false,
    modified: DateTime.now(),
  );

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

  setUpAll(() async {
    AuthService.instance = authService;

    await firestore
        .collection('experiments')
        .doc(experiment.id)
        .set(experiment.toJson());

    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});

    myApp = myApp = TestApp(
      firestore: firestore,
      sps: sharedPreferencesService,
      app: MaterialApp(initialRoute: '/listBirds', routes: {
        '/': (context) => MyHomePage(title: "Nest app"),
        '/listBirds': (context) => ListBirds(firestore: firestore),
        '/editBird': (context) => EditBird(firestore: firestore),
      }),
    );
  });

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

    //reset the database
    await firestore.collection("Birds").doc(chick.band).set(chick.toJson());
  });

  testWidgets("Will navigate to chick if edit button is pressed",
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //check if the list of birds is displayed
    expect(find.byType(ListTile), findsNWidgets(1));

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(EditBird), findsOneWidget);
  });

  testWidgets("Will have repeated measure on experiment for chick",
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //check if the list of birds is displayed
    expect(find.byType(ListTile), findsNWidgets(1));

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(EditBird), findsOneWidget);
    expect(find.text("weight"), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();

    expect(find.text("weight"), findsNWidgets(2));
  });

  testWidgets("Will have single measure from default measures for chick",
      (WidgetTester tester) async {
    sharedPreferencesService.defaultMeasures = [m2];
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //check if the list of birds is displayed
    expect(find.byType(ListTile), findsNWidgets(1));

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(EditBird), findsOneWidget);
    expect(find.text("identity"), findsOneWidget);
  });
}
