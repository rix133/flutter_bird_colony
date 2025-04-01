import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_bird_colony/screens/homepage.dart';
import 'package:flutter_bird_colony/screens/nest/createNest.dart';
import 'package:flutter_bird_colony/screens/nest/editNest.dart';
import 'package:flutter_bird_colony/screens/nest/mapNests.dart';
import 'package:flutter_bird_colony/services/authService.dart';
import 'package:flutter_bird_colony/services/locationService.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'mocks/mockAuthService.dart';
import 'mocks/mockLocationService.dart';
import 'mocks/mockSharedPreferencesService.dart';
import 'testApp.dart';

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
    last_modified: DateTime.now().subtract(Duration(days: 5)),
    discover_date: DateTime.now(),
    responsible: "Admin",
    species: "Common gull",
    measures: [Measure.note()],
  );
  final Nest nest2 = Nest(
    id: "2",
    coordinates: GeoPoint(58.776218, 23.430532),
    accuracy: "3.22m",
    last_modified: DateTime.now().subtract(Duration(days: 5)),
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

  TestApp getInitApp(Object? args) {
    return TestApp(
      firestore: firestore,
      sps: sharedPreferencesService,
      app: MaterialApp(
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
          } else if (settings.name == '/editNest') {
            return MaterialPageRoute(
              builder: (context) => EditNest(
                firestore: firestore,
              ),
              settings: settings, // get nest from settings
            );
          } else if (settings.name == '/mapNests') {
            return MaterialPageRoute(
              builder: (context) => MapNests(
                firestore: firestore, auth: authService),
              settings: RouteSettings(
                arguments: args, // get initial args
              ),
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
  }

  setUpAll(() async {
    //AuthService.instance = authService;
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
    await nests.doc(nest2.id).set(nest2.toJson());
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

  testWidgets("can search for nest 2", (WidgetTester tester) async {
    myApp = getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    var mapFinder = find.byType(GoogleMap);
    expect(mapFinder, findsOneWidget);

    GoogleMap g = mapFinder.first.evaluate().first.widget as GoogleMap;

    expect(g.markers.length, 2);

    // Find the FloatingActionButton with the "search" hero tag and tap it
    Finder searchButton = find.byWidgetPredicate(
      (Widget widget) =>
          widget is FloatingActionButton && widget.heroTag == "search",
    );
    await tester.tap(searchButton);
    await tester.pumpAndSettle();

    // Check if an AlertDialog is present in the widget tree
    expect(find.byType(AlertDialog), findsOneWidget);

    // Find the TextFormField within the AlertDialog and simulate the "done" action
    Finder searchField = find.byType(TextFormField);
    await tester.showKeyboard(searchField);
    await tester.enterText(searchField, "2");
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    g = mapFinder.first.evaluate().first.widget as GoogleMap;
    expect(g.markers.length, 1);

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

  testWidgets("will go to nest when marker is tapped ",
      (WidgetTester tester) async {
    myApp = getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    expect(find.byType(MapNests), findsOneWidget);

    var mapFinder = find.byType(GoogleMap);
    expect(mapFinder, findsOneWidget);

    GoogleMap g = mapFinder.first.evaluate().first.widget as GoogleMap;

    expect(g.markers.length, 2);
    //tap the first marker
    g.markers.first.infoWindow.onTap!();
    await tester.pumpAndSettle();

    //fid the text 1 and tap it
    expect(find.text("1"), findsOneWidget);
    await tester.tap(find.text("1"));
    await tester.pumpAndSettle();
    //expect to be on EditNest page
    expect(find.byType(EditNest), findsOneWidget);
  });

  testWidgets("will get back from nest when marker is tapped and nest is saved",
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
    //tap the first marker
    g.markers.first.infoWindow.onTap!();
    await tester.pumpAndSettle();

    //fid the text 1 and tap it
    expect(find.text("1"), findsOneWidget);
    await tester.tap(find.text("1"));
    await tester.pumpAndSettle();
    //expect to be on EditNest page
    expect(find.byType(EditNest), findsOneWidget);

    //find the save button and tap it
    Finder saveButton = find.byKey(Key("saveButton"));
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    //expect to be on MapNests page
    expect(find.byType(MapNests), findsOneWidget);

    g = mapFinder.first.evaluate().first.widget as GoogleMap;

    expect(g.markers.length, 1);
    //tap the first marker
    g.markers.first.infoWindow.onTap!();
    await tester.pumpAndSettle();
    expect(find.text("1"), findsOneWidget);

    // can go back to nest again issue https://github.com/rix133/flutter_bird_colony/issues/77
    expect(find.text("1"), findsOneWidget);
    await tester.tap(find.text("1"));
    await tester.pumpAndSettle();
    //expect to be on EditNest page
    expect(find.byType(EditNest), findsOneWidget);
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
    expect(g.markers.first.markerId.value, "2");
  });

  testWidgets("will remove a nest marker when firestore is updated",
      (WidgetTester tester) async {
    myApp = getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    expect(find.byType(MapNests), findsOneWidget);

    var mapFinder = find.byType(GoogleMap);
    expect(mapFinder, findsOneWidget);

    GoogleMap g = mapFinder.first.evaluate().first.widget as GoogleMap;

    expect(g.markers.length, 2);
    //remove the nest from firestore
    await nests.doc("1").delete();
    await tester.pumpAndSettle();

    g = mapFinder.first.evaluate().first.widget as GoogleMap;
    expect(g.markers.length, 1);
  });
  testWidgets("will update a nest marker when firestore is updated",
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
    expect(
        ((g.markers.first.icon.toJson() as List))[1], BitmapDescriptor.hueRed);
    //remove the nest from firestore
    await nests.doc("1").update({"last_modified": DateTime.now()});
    await tester.pumpAndSettle();

    g = mapFinder.first.evaluate().first.widget as GoogleMap;
    expect(g.markers.length, 1);
    //expect marker color to ber huegreen
    //print(((g.markers.first.icon.toJson() as List)));
    expect(((g.markers.first.icon.toJson() as List))[1],
        BitmapDescriptor.hueGreen);
  });
}
