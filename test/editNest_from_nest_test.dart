

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/speciesRawAutocomplete.dart';
import 'package:flutter_bird_colony/models/eggStatus.dart';
import 'package:flutter_bird_colony/models/firestore/egg.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_bird_colony/screens/bird/editBird.dart';
import 'package:flutter_bird_colony/screens/homepage.dart';
import 'package:flutter_bird_colony/screens/nest/editEgg.dart';
import 'package:flutter_bird_colony/screens/nest/editNest.dart';
import 'package:flutter_bird_colony/screens/nest/findNest.dart';
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
  late Nest nest;
  final Egg egg = Egg(
      id: "1 egg 1",
      discover_date: DateTime.now().subtract(Duration(days: 2)),
      responsible: "Admin",
      ring: null,
      last_modified: DateTime.now().subtract(Duration(days: 1)),
      status: EggStatus('intact'),
      measures: [Measure.note()]);

  setUpAll(() async {
    //AuthService.instance = authService;
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
                arguments: {'nest': nest}, // get initial nest from object
              ),
            );
          } else if (settings.name == '/findNest') {
            return MaterialPageRoute(
              builder: (context) => FindNest(
                firestore: firestore,
              ),
            );

          }
          else if (settings.name == '/editEgg') {
            return MaterialPageRoute(
              builder: (context) => EditEgg(
                firestore: firestore,
              ),
              settings: RouteSettings(
                arguments: egg, // get initial nest from object
              ),
            );

          } else if(settings.name == '/editBird'){
            return MaterialPageRoute(
              builder: (context) => EditBird(
                firestore: firestore,
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


  });

  setUp(() async {
    //reset nest
    nest = Nest(
      id: "1",
      coordinates: GeoPoint(0, 0),
      accuracy: "3.22m",
      last_modified: DateTime.now().subtract(Duration(days: 1)),
      discover_date: DateTime.now().subtract(Duration(days: 2)),
      first_egg: DateTime.now().subtract(Duration(days: 2)),
      responsible: "Admin",
      species: "Common gull",
      measures: [Measure.note()],
    );

    //reset the database
    await firestore.collection('recent').doc("nest").set({"id":"1"});
    await firestore.collection(DateTime.now().year.toString()).doc(nest.id).set(nest.toJson());
    //add egg to nest
    await firestore.collection(DateTime.now().year.toString()).doc(nest.id).collection("egg").doc(egg.id).set(egg.toJson());

  });
  tearDown(() {
    //empty nests
    firestore.collection(DateTime.now().year.toString()).doc(nest.id).delete();
  });

  testWidgets("Will display add egg and add parent buttons", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    expect(find.text('add egg'), findsOneWidget);
    expect(find.text('add parent'), findsOneWidget);
  });

  testWidgets("Will display nest details", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    expect(find.text('~3.2m'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

   testWidgets("Will have listed species in nest details", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //find that has the species test in textfield
    // Find the SpeciesRawAutocomplete widget
    Finder speciesRawAutocompleteFinder = find.byType(SpeciesRawAutocomplete);
    expect(speciesRawAutocompleteFinder, findsOneWidget);

    // Find the TextField widget which is a descendant of the SpeciesRawAutocomplete widget
    Finder textFieldFinder = find.descendant(
      of: speciesRawAutocompleteFinder,
      matching: find.byType(TextField),
    );
    expect(textFieldFinder, findsOneWidget);

    // Get the TextField widget
    TextField textField = tester.widget(textFieldFinder);

    // Verify if the TextField's controller's text is "Common gull"
    expect(textField.controller?.text, "Common gull");
  });

   testWidgets("will have one egg listed", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();


    expect(find.text('Egg 1 intact 2 days old'), findsOneWidget);
  });

    testWidgets("will navigate to edit egg", (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Egg 1 intact 2 days old'));
      await tester.pumpAndSettle();

      expect(find.byType(EditEgg), findsOneWidget);
      expect(find.text("Nest: 1 egg 1"), findsOneWidget);
    });

testWidgets("will navigate to nest when egg is saved", (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Egg 1 intact 2 days old'));
      await tester.pumpAndSettle();


      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      expect(find.byType(EditNest), findsOneWidget);
    });

 testWidgets("will navigate to nest when egg is deleted", (WidgetTester tester) async {
        await tester.pumpWidget(myApp);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Egg 1 intact 2 days old'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete));
        await tester.pumpAndSettle();

        expect(find.text("Removing item"), findsOneWidget);

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.byType(EditNest), findsOneWidget);
        expect(find.text('Egg 1 intact 2 days old'), findsNothing);
        expect(firestore.collection(DateTime.now().year.toString()).doc(nest.id).collection("egg").doc(egg.id).get(), completion((DocumentSnapshot snapshot) => snapshot.exists == false));
      });

  testWidgets(
      "will navigate to find nest when nest is saved after validation errors",
      (WidgetTester tester) async {
    nest.accuracy = "12.00m";
    nest.save(firestore);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.text("save anyway"), findsOneWidget);

    await tester.tap(find.text('save anyway'));
    await tester.pumpAndSettle();

    expect(find.byType(MyHomePage), findsOneWidget);
  });

  testWidgets(
      "will stay on nest when nest saving is canceled after validation errors",
      (WidgetTester tester) async {
    nest.accuracy = "12.00m";
    nest.save(firestore);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.text("save anyway"), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);

    expect(find.byType(EditNest), findsOneWidget);
  });

  testWidgets("will navigate to find nest when nest is saved",
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.byType(MyHomePage), findsOneWidget);
  });

  testWidgets("will navigate to find nest when nest is deleted", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text("Removing item"), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(firestore.collection(DateTime
        .now()
        .year
        .toString()).doc(nest.id).get(),
        completion((DocumentSnapshot snapshot) => snapshot.exists == false));

    expect(find.byType(MyHomePage), findsOneWidget);

  });
  testWidgets(
      "will add new note on egg when requested", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Egg 1 intact 2 days old'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(3));
  });

    testWidgets(
      "will add new note on nest when requested", (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      // Find the first IconButton that matches the predicate
      Finder firstIconButtonFinder = find.byWidgetPredicate(
            (Widget widget) =>
        widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.add &&
            widget.onPressed != null,
      );

      // Ensure that the IconButton is found
      expect(firstIconButtonFinder, findsOneWidget);

      // Tap on the IconButton
      await tester.tap(firstIconButtonFinder.first);
      await tester.pumpAndSettle();

      // Check that a new TextFormField is added
      expect(find.byType(TextFormField), findsNWidgets(3));

  });
    testWidgets("will go to edit bird when add parent is pressed", (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.text('add parent'));
      await tester.pumpAndSettle();

      expect(find.byType(EditBird), findsOneWidget);
    });

  testWidgets("will go to edit bird when egg is long pressed", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Egg 1 intact 2 days old'));
    await tester.pumpAndSettle();

    expect(find.byType(EditBird), findsOneWidget);
  });

  testWidgets("will go to edit bird when add egg is long pressed", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    await tester.longPress(find.text('add egg'));
    await tester.pumpAndSettle();

    expect(find.byType(EditBird), findsOneWidget);
  });
  }
