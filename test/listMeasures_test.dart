import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/models/firestore/bird.dart';
import 'package:kakrarahu/models/firestore/egg.dart';
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

  late Measure measure;
  late Nest nest;
  late Egg egg;
  late Bird bird;

  setUpAll(() async {
    AuthService.instance = authService;
    LocationService.instance = locationAccuracy10;
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
              settings: RouteSettings(
                arguments: arg, // get initial nest from object
              ),
            );
          } else if (settings.name == '/editBird') {
            return MaterialPageRoute(
              builder: (context) => EditBird(
                firestore: firestore,
              ),
              settings: RouteSettings(
                arguments: {'bird': arg}, // get initial bird from object
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
    measure = Measure(
      name: 'FID',
      type: 'egg',
      unit: 'm',
      value: '',
      repeated: true,
      isNumber: true,
      modified: DateTime.now(),
    );
    nest = Nest(
      id: "1",
      coordinates: GeoPoint(0, 0),
      accuracy: "12.22m",
      last_modified: DateTime.now().subtract(Duration(days: 1)),
      discover_date: DateTime.now().subtract(Duration(days: 2)),
      first_egg: DateTime.now().subtract(Duration(days: 2)),
      responsible: "Admin",
      species: "Common gull",
      measures: [measure],
    );
    egg = Egg(
        id: "1 egg 1",
        discover_date: DateTime.now().subtract(Duration(days: 2)),
        responsible: "Admin",
        ring: null,
        last_modified: DateTime.now().subtract(Duration(days: 1)),
        status: "intact",
        measures: [measure]);

    bird = Bird(
        id: "AA11",
        ringed_date: DateTime.now().subtract(Duration(days: 2)),
        responsible: "Admin",
        band: "AA11",
        last_modified: DateTime.now().subtract(Duration(days: 1)),
        species: "Common gull",
        measures: [measure],
        ringed_as_chick: true);
  });

  testWidgets("will add new repeated measure on egg",
      (WidgetTester tester) async {
    myApp = getInitApp('/editEgg', egg);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    // Find the first IconButton that matches the predicate
    Finder iconButtonFinder = find.byWidgetPredicate(
      (Widget widget) =>
          widget is IconButton &&
          widget.icon is Icon &&
          (widget.icon as Icon).icon == Icons.add &&
          widget.onPressed != null,
    );

    // Ensure that the IconButton is found
    expect(iconButtonFinder, findsNWidgets(2));

    // Tap on the IconButton
    await tester.tap(iconButtonFinder.first);
    await tester.pumpAndSettle();

    // Check that a new TextFormField is added
    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets("will add new repeated measure on nest",
      (WidgetTester tester) async {
    myApp = getInitApp('/editNest', nest);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    // Find the first IconButton that matches the predicate
    Finder iconButtonFinder = find.byWidgetPredicate(
      (Widget widget) =>
          widget is IconButton &&
          widget.icon is Icon &&
          (widget.icon as Icon).icon == Icons.add &&
          widget.onPressed != null,
    );

    // Ensure that the IconButton is found
    expect(iconButtonFinder, findsNWidgets(2));

    // Tap on the IconButton
    await tester.tap(iconButtonFinder.first);
    await tester.pumpAndSettle();

    // Check that a new TextFormField is added
    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets("will write egg repeated measure to firestore",
      (WidgetTester tester) async {
    myApp = getInitApp('/editEgg', egg);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    Finder iconButtonFinder = find.byWidgetPredicate(
      (Widget widget) =>
          widget is IconButton &&
          widget.icon is Icon &&
          (widget.icon as Icon).icon == Icons.add &&
          widget.onPressed != null,
    );

    // Find the first textfield that matches the predicate
    Finder textFinder = find.byWidgetPredicate((Widget widget) =>
        widget is InputDecorator && widget.decoration.labelText == 'FID (m)');

    // Ensure that the IconButton is found
    expect(textFinder, findsNWidgets(1));

    //enter text to the textfield
    await tester.enterText(textFinder, '123');
    await tester.pumpAndSettle();

    //expect that the text is visible
    expect(find.text('123'), findsOneWidget);

    // Tap on the IconButton
    await tester.tap(iconButtonFinder.first);
    await tester.pumpAndSettle();

    textFinder = find.byWidgetPredicate((Widget widget) =>
        widget is InputDecorator && widget.decoration.labelText == 'FID (m)');

    expect(textFinder, findsNWidgets(1));

    // Check that a new TextFormField is added
    expect(find.byType(TextFormField), findsNWidgets(4));

    // Check that the TextFormField controller text is "???"
    expect(find.text('???'), findsOneWidget);

    //tap the save button
    await tester.tap(find.text("save"));
    await tester.pumpAndSettle();

    //expect that the egg is saved
    Egg savedEgg = await firestore
        .collection(DateTime.now().year.toString())
        .doc(nest.id)
        .collection("egg")
        .doc(egg.id)
        .get()
        .then((value) => Egg.fromDocSnapshot(value));
    expect(savedEgg.measures.length, 2); //the second one is the default Note
    expect(savedEgg.measures[0].value, '123');
  });

  testWidgets("will write nest repeated measure to firestore",
      (WidgetTester tester) async {
    myApp = getInitApp('/editNest', nest);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    Finder iconButtonFinder = find.byWidgetPredicate(
      (Widget widget) =>
          widget is IconButton &&
          widget.icon is Icon &&
          (widget.icon as Icon).icon == Icons.add &&
          widget.onPressed != null,
    );

    // Find the first textfield that matches the predicate
    Finder textFinder = find.byWidgetPredicate((Widget widget) =>
        widget is InputDecorator && widget.decoration.labelText == 'FID (m)');
    expect(textFinder, findsNWidgets(1));
    //enter text to the textfield
    await tester.enterText(textFinder, '123');
    await tester.pumpAndSettle();

    //expect that the text is visible
    expect(find.text('123'), findsOneWidget);

    // Tap on the IconButton
    await tester.tap(iconButtonFinder.first);
    await tester.pumpAndSettle();

    textFinder = find.byWidgetPredicate((Widget widget) =>
        widget is InputDecorator && widget.decoration.labelText == 'FID (m)');

    expect(textFinder, findsNWidgets(1));

    // Check that the TextFormField controller text is "???"
    expect(find.text('???'), findsOneWidget);

    expect(find.byType(TextFormField), findsNWidgets(4));

    //check that at least one textforfield co

    //find the save button
    Finder saveButton = find.byIcon(Icons.save);
    await tester.ensureVisible(saveButton);

    //tap the save button
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    //expect that the nest is saved
    Nest savedNest = await firestore
        .collection(DateTime.now().year.toString())
        .doc(nest.id)
        .get()
        .then((value) => Nest.fromDocSnapshot(value));
    expect(savedNest.measures.length, 2); //the second one is the default Note
    expect(savedNest.measures[0].value, '123');
  });

  testWidgets("will write several  egg repeated measure to firestore",
      (WidgetTester tester) async {
    myApp = getInitApp('/editEgg', egg);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    Finder iconButtonFinder = find.byWidgetPredicate(
      (Widget widget) =>
          widget is IconButton &&
          widget.icon is Icon &&
          (widget.icon as Icon).icon == Icons.add &&
          widget.onPressed != null,
    );

    // Find the first textfield that matches the predicate
    Finder textFinder = find.byWidgetPredicate((Widget widget) =>
        widget is InputDecorator && widget.decoration.labelText == 'FID (m)');
    expect(textFinder, findsNWidgets(1));
    //enter text to the textfield
    await tester.enterText(textFinder, '123');
    await tester.pumpAndSettle();

    //expect that the text is visible
    expect(find.text('123'), findsOneWidget);

    // Tap on the IconButton
    await tester.tap(iconButtonFinder.first);
    await tester.pumpAndSettle();

    textFinder = find.byWidgetPredicate((Widget widget) =>
        widget is InputDecorator && widget.decoration.labelText == 'FID (m)');

    expect(textFinder, findsNWidgets(1));

    // Check that the TextFormField controller text is "???"
    expect(find.text('???'), findsOneWidget);

    //enter text to the textfield
    await tester.enterText(textFinder, '456');
    await tester.pumpAndSettle();

    //expect that the text is visible
    expect(find.text('456'), findsOneWidget);

    // Tap on the IconButton
    await tester.tap(iconButtonFinder.first);
    await tester.pumpAndSettle();

    textFinder = find.byWidgetPredicate((Widget widget) =>
        widget is InputDecorator && widget.decoration.labelText == 'FID (m)');

    expect(textFinder, findsNWidgets(1));

    // Check that the TextFormField controller text is "???"
    expect(find.text('???'), findsNWidgets(2));

    //find the save button
    Finder saveButton = find.byIcon(Icons.save);
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    //tap the save button
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    //expect that the egg is saved
    Egg savedEgg = await firestore
        .collection(DateTime.now().year.toString())
        .doc(nest.id)
        .collection("egg")
        .doc(egg.id)
        .get()
        .then((value) => Egg.fromDocSnapshot(value));
    expect(savedEgg.measures.length, 3); //the third one is the default Note
    expect(savedEgg.measures[0].value, '123');
    expect(savedEgg.measures[1].value, '456');
  });

  testWidgets("will retain egg repeated measure value after re-save firestore",
      (WidgetTester tester) async {
    egg.measures[0].value = '123';
    await egg.save(firestore);
    Egg savedEgg = await firestore
        .collection(DateTime.now().year.toString())
        .doc(nest.id)
        .collection("egg")
        .doc(egg.id)
        .get()
        .then((value) => Egg.fromDocSnapshot(value));

    myApp = getInitApp('/editEgg', savedEgg);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    // Check that the TextFormField controller text is "???"
    expect(find.text('???'), findsNWidgets(1));

    Finder iconButtonFinder = find.byWidgetPredicate(
      (Widget widget) =>
          widget is IconButton &&
          widget.icon is Icon &&
          (widget.icon as Icon).icon == Icons.add &&
          widget.onPressed != null,
    );

    //tap the icon button
    await tester.tap(iconButtonFinder.first);
    await tester.pumpAndSettle();

    // Find the first textfield that matches the predicate FID (m)
    Finder textFinder = find.byWidgetPredicate((Widget widget) =>
        widget is InputDecorator && widget.decoration.labelText == 'FID (m)');

    //enter text to the textfield
    await tester.enterText(textFinder, '321');

    //find the save button
    Finder saveButton = find.byIcon(Icons.save);
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    //tap the save button
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    //expect that the egg is saved
    Egg reSavedEgg = await firestore
        .collection(DateTime.now().year.toString())
        .doc(nest.id)
        .collection("egg")
        .doc(egg.id)
        .get()
        .then((value) => Egg.fromDocSnapshot(value));
    expect(reSavedEgg.measures.length, 3); //the second one is the default Note
    expect(reSavedEgg.measures[0].value, '123');
    expect(reSavedEgg.measures[1].value, '321');
  });

  testWidgets("will retain nest repeated measure value after re-save firestore",
      (WidgetTester tester) async {
    nest.measures[0].value = '123';
    await nest.save(firestore);
    Nest savedNest = await firestore
        .collection(DateTime.now().year.toString())
        .doc(nest.id)
        .get()
        .then((value) => Nest.fromDocSnapshot(value));

    myApp = getInitApp('/editNest', savedNest);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    // Check that the TextFormField controller text is "???"
    expect(find.text('???'), findsNWidgets(1));

    Finder iconButtonFinder = find.byWidgetPredicate(
      (Widget widget) =>
          widget is IconButton &&
          widget.icon is Icon &&
          (widget.icon as Icon).icon == Icons.add &&
          widget.onPressed != null,
    );

    //tap the icon button
    await tester.tap(iconButtonFinder.first);
    await tester.pumpAndSettle();

    // Find the first textfield that matches the predicate FID (m)
    Finder textFinder = find.byWidgetPredicate((Widget widget) =>
        widget is InputDecorator && widget.decoration.labelText == 'FID (m)');

    //enter text to the textfield
    await tester.enterText(textFinder, '321');
    await tester.pumpAndSettle();

    //find the save button
    Finder saveButton = find.byIcon(Icons.save);
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    //tap the save button
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    //expect that the nest is saved
    Nest reSavedNest = await firestore
        .collection(DateTime.now().year.toString())
        .doc(nest.id)
        .get()
        .then((value) => Nest.fromDocSnapshot(value));
    expect(reSavedNest.measures.length, 3); //the third one is the default Note
    expect(reSavedNest.measures[0].value, '123');
    expect(reSavedNest.measures[1].value, '321');
  });

  testWidgets("will retain bird repeated measure value after re-save firestore",
      (WidgetTester tester) async {
    bird.measures[0].value = '123';
    await bird.save(firestore);
    Bird savedBird = await firestore
        .collection("Birds")
        .doc(bird.id)
        .get()
        .then((value) => Bird.fromDocSnapshot(value));

    myApp = getInitApp('/editBird', savedBird);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    // Check that the TextFormField controller text is "???"
    expect(find.text('???'), findsNWidgets(1));

    Finder iconButtonFinder = find.byWidgetPredicate(
      (Widget widget) =>
          widget is IconButton &&
          widget.icon is Icon &&
          (widget.icon as Icon).icon == Icons.add &&
          widget.onPressed != null,
    );

    //tap the icon button
    await tester.tap(iconButtonFinder.first);
    await tester.pumpAndSettle();

    // Find the first textfield that matches the predicate FID (m)
    Finder textFinder = find.byWidgetPredicate((Widget widget) =>
        widget is InputDecorator && widget.decoration.labelText == 'FID (m)');

    //enter text to the textfield
    await tester.enterText(textFinder, '321');
    await tester.pumpAndSettle();

    for (var t in find.byType(Text).evaluate()) {
      print((t.widget as Text).data);
    }

    //find the save button
    Finder saveButton = find.byIcon(Icons.save);
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    //tap the save button
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    //expect that the bird is saved
    Bird reSavedBird = await firestore
        .collection("Birds")
        .doc(bird.id)
        .get()
        .then((value) => Bird.fromDocSnapshot(value));
    for (Measure m in reSavedBird.measures) {
      print(m.toJson());
    }
    expect(reSavedBird.measures.length, 3); //the third one is the default Note
    expect(reSavedBird.measures[0].value, '123');
    expect(reSavedBird.measures[1].value, '321');
  });
}
