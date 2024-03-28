
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_bird_colony/screens/homepage.dart';
import 'package:flutter_bird_colony/screens/nest/editNest.dart';
import 'package:flutter_bird_colony/screens/nest/findNest.dart';
import 'package:flutter_bird_colony/screens/settings/settings.dart';
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
  final Nest nest = Nest(
    id: "1",
    coordinates: GeoPoint(0, 0),
    accuracy: "3.22m",
    last_modified: DateTime.now(),
    discover_date: DateTime.now(),
    responsible: "Admin",
    species: "test",
    measures: [Measure.numeric(name: "test", required: true)],
  );

  setUpAll(() async {
    AuthService.instance = authService;
    LocationService.instance = locationAccuracy10;


    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});
    myApp = ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
          initialRoute: '/',
          routes: {
            '/': (context) => MyHomePage(title: "Nest app"),
            '/settings': (context) => SettingsPage(firestore: firestore),
            '/editNest':(context)=>EditNest(firestore: firestore),
            '/findNest':(context)=>FindNest(firestore: firestore),
          }
      ),
    );
  });

  setUp(() async {
    //reset the database
    await firestore.collection('recent').doc("nest").set({"id":"1"});
    await firestore.collection(DateTime.now().year.toString()).doc(nest.id).set(nest.toJson());

  });

  testWidgets("Can go to modify nest page through search", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //find the find nest button on homepage
    await tester.tap(find.text("find nest"));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '1');
    await tester.pumpAndSettle();

    await tester.tap(find.text("Find nest"));
    await tester.pumpAndSettle();

    //check if routed to nestManage
    expect(find.byType(EditNest), findsOneWidget);
  });

  testWidgets(
      "Can go to modify nest page through search and save nest without filling required measure",
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //find the find nest button on homepage
    await tester.tap(find.text("find nest"));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '1');
    await tester.pumpAndSettle();

    await tester.tap(find.text("Find nest"));
    await tester.pumpAndSettle();

    //check if routed to nestManage
    expect(find.byType(EditNest), findsOneWidget);

    //save the nest
    await tester.tap(find.byKey(Key("saveButton")));
    await tester.pumpAndSettle();

    //find the AlertDialog
    expect(find.byType(AlertDialog), findsOneWidget);
    //find the save anyway button
    await tester.tap(find.text("save anyway"));
    await tester.pumpAndSettle();
    //expect to be back in the find nest page
    expect(find.byType(FindNest), findsOneWidget);
  });

  testWidgets(
      "Can go to modify nest page through search and save nest with filling required measure",
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //find the find nest button on homepage
    await tester.tap(find.text("find nest"));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '1');
    await tester.pumpAndSettle();

    await tester.tap(find.text("Find nest"));
    await tester.pumpAndSettle();

    //check if routed to nestManage
    expect(find.byType(EditNest), findsOneWidget);

    //fill the required measure that has a label of test
    // Find the first textfield that matches the predicate
    Finder textFinder = find.byWidgetPredicate((Widget widget) =>
        widget is InputDecorator && widget.decoration.labelText == 'test');

    await tester.enterText(textFinder, '1');

    //save the nest
    await tester.tap(find.byKey(Key("saveButton")));
    await tester.pumpAndSettle();

    //find the AlertDialog
    expect(find.byType(AlertDialog), findsNothing);

    //expect to be back in the find nest page
    expect(find.byType(FindNest), findsOneWidget);
  });

  testWidgets("Can go to modify nest page through search and delete nest",
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //find the find nest button on homepage
    await tester.tap(find.text("find nest"));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '1');
    await tester.pumpAndSettle();

    await tester.tap(find.text("Find nest"));
    await tester.pumpAndSettle();

    //check if routed to nestManage
    expect(find.byType(EditNest), findsOneWidget);

    //delete the nest
    await tester.tap(find.byKey(Key("deleteButton")));
    await tester.pumpAndSettle();

    //find the AlertDialog
    expect(find.byType(AlertDialog), findsOneWidget);

    //find the delete  button
    await tester.tap(find.text("Delete"));
    await tester.pumpAndSettle();

    //check firestore nest deletion
    var nestDoc = await firestore
        .collection(DateTime.now().year.toString())
        .doc(nest.id)
        .get();
    expect(nestDoc.exists, false);

    //expect to be back in the find nest page
    expect(find.byType(FindNest), findsOneWidget);
  });

  testWidgets("FindNest: search for a nest that does not exist", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //find the find nest button on homepage
    await tester.tap(find.text("find nest"));
    await tester.pumpAndSettle();


    //go for empty nest as well
    await tester.tap(find.text("Find nest"));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '2');
    await tester.pumpAndSettle();

    await tester.tap(find.text("Find nest"));
    await tester.pump(Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Check for the SnackBar
    expect(find.byType(SnackBar), findsOneWidget);
    // Check the text inside the SnackBar
    expect(find.text('Nest 2 does not exist'), findsOneWidget);
  });
}