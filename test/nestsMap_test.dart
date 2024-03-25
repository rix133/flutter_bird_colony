import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kakrarahu/models/firestore/experiment.dart';
import 'package:kakrarahu/models/firestore/nest.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/screens/homepage.dart';
import 'package:kakrarahu/screens/nest/createNest.dart';
import 'package:kakrarahu/screens/nest/mapNests.dart';
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
  CollectionReference nests = firestore.collection(DateTime.now().year.toString());
  late Widget myApp;
  final userEmail = "test@example.com";
  final Nest nest = Nest(
    id: "1",
    coordinates: GeoPoint(58.766218, 23.430432),
    accuracy: "3.22m",
    last_modified: DateTime.now(),
    discover_date: DateTime.now(),
    responsible: "Admin",
    species: "Common gull",
    measures: [Measure.note()],
  );

  final Experiment experiment = Experiment(
    id: "1",
    name: "New Experiment",
    description: "Test experiment",
    last_modified: DateTime.now(),
    created: DateTime.now(),
    year: DateTime.now().year,
    responsible: "Admin",
  );

  Widget getInitApp(Object? args) {
    return (ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
        initialRoute: '/mapNests',
        onGenerateRoute: (settings) {
          if (settings.name == '/createNest') {
            return MaterialPageRoute(
              builder: (context) => CreateNest(
                firestore: firestore,
              ),
              settings: RouteSettings(
                arguments: nest, // get initial nest from firestore
              ),
            );
          } else if (settings.name == '/mapNests') {
            return MaterialPageRoute(
              builder: (context) => MapNests(
                firestore: firestore,
              ),
              settings: RouteSettings(
                arguments: args, // get initial args
              ),
            );
          }
          // Other routes...
          return MaterialPageRoute(
            builder: (context) => MyHomePage(title: "Nest app"),
          );
        },
      ),
    ));
  }

  setUpAll(() async {
    AuthService.instance = authService;
    LocationService.instance = locationAccuracy10;

    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});
    await firestore
        .collection('experiments')
        .doc(experiment.id)
        .set(experiment.toJson());
  });

  setUp(() async {
    //reset the database
    await firestore.collection('recent').doc("nest").set({"id": "1"});
    await nests
        .doc(nest.id)
        .set(nest.toJson());
  });

  testWidgets("Will render nest map", (WidgetTester tester) async {
    myApp = getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    expect(find.byType(MapNests), findsOneWidget);
  });

  testWidgets("Check if Google Map exists", (WidgetTester tester) async {
    myApp = getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    Finder googleMap  = find.byType(GoogleMap);
    expect(googleMap, findsOneWidget);
  });

  testWidgets("Widget has 5 floating action buttons", (WidgetTester tester) async {
    myApp = getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    Finder fab = find.byType(FloatingActionButton);
    expect(fab, findsNWidgets(5));
  });

  testWidgets("tap on add floating action button redirects to nest create", (WidgetTester tester) async {
    myApp = getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    Finder addNest = find.byIcon(Icons.add);
    await tester.tap(addNest);
    await tester.pumpAndSettle();
    expect(find.byType(CreateNest), findsOneWidget);
  });

  testWidgets("can search for nests", (WidgetTester tester) async {
    myApp = getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();


    // Find the FloatingActionButton with the "search" hero tag and tap it
    Finder searchButton = find.byWidgetPredicate(
          (Widget widget) => widget is FloatingActionButton && widget.heroTag == "search",
    );
    await tester.tap(searchButton);
    await tester.pumpAndSettle();

    // Check if an AlertDialog is present in the widget tree
    expect(find.byType(AlertDialog), findsOneWidget);

    // Find the TextFormField within the AlertDialog and simulate the "done" action
    Finder searchField = find.byType(TextFormField);
    await tester.showKeyboard(searchField);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Check if the AlertDialog is no longer present in the widget tree
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets("can update location", (WidgetTester tester) async {
    myApp = getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    Finder updateLocation = find.byIcon(Icons.my_location);
    await tester.tap(updateLocation);
    await tester.pumpAndSettle();
  });

  testWidgets("will read route arguments nest_ids",
      (WidgetTester tester) async {
    myApp = getInitApp({
      "nest_ids": ["1"]
    });
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    expect(find.byType(MapNests), findsOneWidget);

    var mapFinder = find.byType(GoogleMap);
    expect(mapFinder, findsOneWidget);

    GoogleMap g = mapFinder.first.evaluate().first.widget as GoogleMap;

    expect(g.markers.length, 1);
  });

  testWidgets("will show markers of different year",
      (WidgetTester tester) async {
    DateTime then = DateTime.now().subtract(Duration(days: 365));
    Nest nest2 = Nest(
      id: "2",
      coordinates: GeoPoint(58.766218, 23.430432),
      accuracy: "3.22m",
      last_modified: then,
      discover_date: then,
      responsible: "Admin",
      species: "Common gull",
      measures: [Measure.note()],
    );
    await firestore
        .collection(then.year.toString())
        .doc(nest2.id)
        .set(nest2.toJson());
    myApp = getInitApp({
      "nest_ids": ["2"],
      "year": then.year.toString()
    });
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    var mapFinder = find.byType(GoogleMap);
    expect(mapFinder, findsOneWidget);

    GoogleMap g = mapFinder.first.evaluate().first.widget as GoogleMap;

    expect(g.markers.length, 1);
  });
}
