import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/design/speciesRawAutocomplete.dart';
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

  Bird parent = Bird(
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
    parent = Bird(
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

  testWidgets(
      "Will load edit bird with nest and parent", (WidgetTester tester) async {
    myApp = getInitApp({"nest": nest, "bird": parent});
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    expect(find.byType(EditBird), findsOneWidget);
  });

  testWidgets(
      "Will load edit bird with nest only", (WidgetTester tester) async {
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

  testWidgets("Will load nest default bird if cant find it from firestore", (WidgetTester tester) async {
    parent.band = "not in firestore";
    parent.id = null;
    myApp = getInitApp({"bird": parent,"nest": nest});
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    expect(find.byType(EditBird), findsOneWidget);
  });

  testWidgets("Will load nest default bird without band", (WidgetTester tester) async {
      parent.band = "";
    myApp = getInitApp({"bird": parent,"nest": nest});
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    expect(find.byType(EditBird), findsOneWidget);
  });

  testWidgets("Will load bird without band", (WidgetTester tester) async {
    parent.band = "";
    myApp = getInitApp({"bird": parent});
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    expect(find.byType(EditBird), findsOneWidget);
  });

  testWidgets("Will display metal band", (WidgetTester tester) async {
    myApp = getInitApp({"bird": parent});
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    expect(find.text("Metal: AA1234"), findsOneWidget);
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
    await tester.tap(find.text("save"));
    await tester.pumpAndSettle();
    //expect to find the bird in firestore
    var bird = await firestore.collection("Birds").doc("AA1235").get();
    expect(bird.exists, true);
  });

  testWidgets("Will set next band on egg", (WidgetTester tester) async {
    myApp = getInitApp({"nest": nest, "egg": egg});
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //fnd tnext band button
    expect(find.text("AA1235"), findsOneWidget);
    await tester.tap(find.text("AA1235"));
    await tester.pumpAndSettle();

    //save the bird
    await tester.tap(find.text("save"));
    await tester.pumpAndSettle();
    //expect to find the bird in firestore
    var bird = await firestore.collection("Birds").doc("AA1235").get();
    expect(bird.exists, true);
  });

  testWidgets("Will save color band on parent", (WidgetTester tester) async {
    myApp = getInitApp({"bird": parent});
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    final finder = find.byWidgetPredicate(
          (Widget widget) =>
      widget is InputDecorator &&
          widget.decoration.labelText == 'color ring'
    );

    //print labels of all input decorators
    //for (var item in tester.allWidgets.whereType<InputDecorator>()) {
    //  print(item.decoration.labelText);
    //}


    expect(finder, findsOneWidget);

    await tester.enterText(finder, "A1b2");
    await tester.pumpAndSettle();


    //save the bird
    await tester.tap(find.text("save"));
    await tester.pumpAndSettle();
    //expect to find the bird in firestore
    var bird = await firestore.collection("Birds").doc("AA1234").get();
    expect(bird.exists, true);
    expect(bird.data()!['color_band'], "A1B2");
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
    await tester.tap(find
        .byType(ListTile)
        .first);
    await tester.pumpAndSettle();

    //expect the textfield to read "Arctic tern"
    expect(find.text("Arctic tern"), findsOneWidget);
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
    var bird = await firestore.collection("Birds").doc("AA1234").get();
    expect(bird.exists, false);
  });


}