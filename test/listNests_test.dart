import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/speciesRawAutocomplete.dart';
import 'package:flutter_bird_colony/models/eggStatus.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/models/firestore/egg.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_bird_colony/screens/homepage.dart';
import 'package:flutter_bird_colony/screens/nest/editNest.dart';
import 'package:flutter_bird_colony/screens/nest/listNests.dart';
import 'package:flutter_bird_colony/screens/nest/mapNests.dart';
import 'package:flutter_bird_colony/services/authService.dart';
import 'package:flutter_bird_colony/services/locationService.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/mockAuthService.dart';
import 'mocks/mockLocationService.dart';
import 'mocks/mockNavigatorObserver.dart';
import 'mocks/mockSharedPreferencesService.dart';
import 'testApp.dart';

void main() {
  final authService = MockAuthService();
  final mockObserver = MockNavigatorObserver();
  final sharedPreferencesService = MockSharedPreferencesService();
  final firestore = FakeFirebaseFirestore();
  MockLocationAccuracy10 locationAccuracy10 = MockLocationAccuracy10();

  late TestApp myApp;
  final userEmail = "test@example.com";
  final Nest nest1 = Nest(
    id: "1",
    coordinates: GeoPoint(0, 0),
    accuracy: "3.22m",
    last_modified: DateTime.now().subtract(Duration(days: 2)),
    discover_date: DateTime.now().subtract(Duration(days: 2)),
    first_egg: DateTime.now().subtract(Duration(days: 2)),
    responsible: "Admin",
    species: "Common gull",
    measures: [Measure.note()],
  );

  final Nest nest2 = Nest(
    id: "2",
    coordinates: GeoPoint(0, 0),
    accuracy: "1.22m",
    last_modified: DateTime.now(),
    discover_date: DateTime.now(),
    responsible: "Admin",
    species: "test",
    measures: [Measure.note()],
  );

  final Nest nest3 = Nest(
    id: "234",
    coordinates: GeoPoint(0, 0),
    accuracy: "3.22m",
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
      status: EggStatus('intact'),
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
    //AuthService.instance = authService;
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

    myApp = myApp = TestApp(
      firestore: firestore,
      sps: sharedPreferencesService,
      app: MaterialApp(initialRoute: '/listNests', routes: {
        '/': (context) => MyHomePage(title: "Nest app", auth: authService),
        '/listNests': (context) => ListNests(firestore: firestore),
            '/editNest': (context) => EditNest(firestore: firestore),
        '/mapNests': (context) =>
            MapNests(firestore: firestore, auth: authService),
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
  testWidgets("will filter nests by species name", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(2));
    //find the filter button
    await tester.tap(find.byIcon(Icons.filter_alt));
    await tester.pumpAndSettle();
    //find the species input

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

    // Enter the text "Common gull" into the TextField
    await tester.enterText(textFieldFinder, "Common gull");
    await tester.pumpAndSettle();
    // tap the last item in the list its the popup from the autocomplete
    await tester.tap(find.byType(ListTile).last);
    await tester.pumpAndSettle();

    //tap the close button
    await tester.tap(find.text("Close"));


    //check if the list of birds is displayed
    expect(find.byType(ListTile), findsNWidgets(1));
  });

  testWidgets("will filter nests by nest name", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    //find the search input
    await tester.enterText(find.byType(TextField), "1");
    await tester.pumpAndSettle();

    //check if the list of birds is displayed
    expect(find.byType(ListTile), findsNWidgets(1));
  });
  testWidgets("filter by min and max location accuracy", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    //find the filter button
    await tester.tap(find.byIcon(Icons.filter_alt));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(2));
    //find the min nest age input
    await tester.enterText(find.byKey(Key("Loc accuracyMin")), "1");
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));

    //find the max nest age input
    await tester.enterText(find.byKey(Key("Loc accuracyMax")), "3");
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(1));
  });

  testWidgets("filter by min and max first egg age", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    //find the filter button
    await tester.tap(find.byIcon(Icons.filter_alt));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(2));
    //find the min nest age input
    await tester.enterText(find.byKey(Key("First egg ageMin")), "1");
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(1));

    //find the max nest age input
    await tester.enterText(find.byKey(Key("First egg ageMax")), "4");
    await tester.pumpAndSettle();
    //check if the list of birds is displayed
    expect(find.byType(ListTile), findsNWidgets(1));

    await tester.enterText(find.byKey(Key("First egg ageMin")), "3");
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(0));
  });


  testWidgets("filter by min and max nest age", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    //find the filter button
    await tester.tap(find.byIcon(Icons.filter_alt));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(2));
    //find the min nest age input
    await tester.enterText(find.byKey(Key("Nest ageMin")), "1");
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(1));

    //find the max nest age input
    await tester.enterText(find.byKey(Key("Nest ageMax")), "4");
    await tester.pumpAndSettle();
    //check if the list of birds is displayed
    expect(find.byType(ListTile), findsNWidgets(1));
  });

  testWidgets('Test if _downloadConfirmationDialog is shown', (WidgetTester tester) async {
    // Build your app and trigger a frame.
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    // Find the download button.
    var downloadButton = find.byIcon(Icons.download);

    // Verify that the button is in the screen.
    expect(downloadButton, findsOneWidget);

    // Tap the download button.
    await tester.tap(downloadButton);
    await tester.pump();


    // Check if the AlertDialog is shown.
    expect(find.byType(AlertDialog), findsOneWidget);

    //tap the no button
    await tester.tap(find.text("OK"));
    await tester.pumpAndSettle();

    //chekc that alert dialog is gone
    expect(find.byType(AlertDialog), findsNothing);
  });
  testWidgets("can clear some filters", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    //find the filter button
    await tester.tap(find.byIcon(Icons.filter_alt));
    await tester.pumpAndSettle();
    //find the year input dropdown
    await tester.enterText(find.byKey(Key("Nest ageMin")), "1");
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(1));


    Finder speciesRawAutocompleteFinder = find.byType(SpeciesRawAutocomplete);
    expect(speciesRawAutocompleteFinder, findsOneWidget);

    // Find the TextField widget which is a descendant of the SpeciesRawAutocomplete widget
    Finder textFieldFinder = find.descendant(
      of: speciesRawAutocompleteFinder,
      matching: find.byType(TextField),
    );
    expect(textFieldFinder, findsOneWidget);

    // Enter the text "Common gull" into the TextField
    await tester.enterText(textFieldFinder, "Common gull");
    await tester.pumpAndSettle();
    // tap the last item in the list its the popup from the autocomplete
    await tester.tap(find.byType(ListTile).last);
    await tester.pumpAndSettle();

    //tap the close button
    await tester.tap(find.text("Clear all"));
    await tester.pumpAndSettle();

    //check if the list of birds is displayed
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets("will show all nests on the map from another year",
      (WidgetTester tester) async {
    final mapRoute = MaterialPageRoute(builder: (_) => Container());
    await tester.pumpWidget(
      TestApp(
        firestore: firestore,
        sps: sharedPreferencesService,
        app: MaterialApp(
            home: ListNests(firestore: firestore),
            navigatorObservers: [mockObserver],
            onGenerateRoute: (RouteSettings settings) {
              if (settings.name == '/mapNests') {
                expect(settings.arguments, {
                  "nest_ids": ["234"],
                  "year": "2023"
                });
                return mapRoute;
              }
              return null;
            }),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));

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

    // Tap the showFilteredNestButton button
    await tester.tap(find.byKey(Key("showFilteredNestButton")));
    await tester.pumpAndSettle();
  });

  testWidgets("will show all nests on the map", (WidgetTester tester) async {
    final mapRoute = MaterialPageRoute(builder: (_) => Container());
    await tester.pumpWidget(
      TestApp(
        firestore: firestore,
        sps: sharedPreferencesService,
        app: MaterialApp(
            home: ListNests(firestore: firestore),
            navigatorObservers: [mockObserver],
            onGenerateRoute: (RouteSettings settings) {
              if (settings.name == '/mapNests') {
                expect(settings.arguments, {
                  "nest_ids": ["1", "2"],
                  "year": DateTime.now().year.toString()
                });
                return mapRoute;
              }
              return null;
            }),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));

    // Tap the showFilteredNestButton button
    await tester.tap(find.byKey(Key("showFilteredNestButton")));
    await tester.pumpAndSettle();
  });

  testWidgets("will show only filtered nests on the map",
      (WidgetTester tester) async {
    final mapRoute = MaterialPageRoute(builder: (_) {
      return (Container());
    });
    await tester.pumpWidget(
      TestApp(
        firestore: firestore,
        sps: sharedPreferencesService,
        app: MaterialApp(
            home: ListNests(firestore: firestore),
            navigatorObservers: [mockObserver],
            onGenerateRoute: (RouteSettings settings) {
              if (settings.name == '/mapNests') {
                expect(settings.arguments, {
                  "nest_ids": ["1"],
                  "year": DateTime.now().year.toString()
                });
                return mapRoute;
              }
              return null;
            }),
      ),
    );
    await tester.pumpAndSettle();
    //find the search input
    await tester.enterText(find.byType(TextField), "1");
    await tester.pumpAndSettle();

    //check if the list of birds is displayed
    expect(find.byType(ListTile), findsNWidgets(1));

    // Tap the showFilteredNestButton button
    await tester.tap(find.byKey(Key("showFilteredNestButton")));
    await tester.pumpAndSettle();
  });

  testWidgets("will show alertdialog when listTile is tapped",
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    //find the search input
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    //check if the list of birds is displayed
        expect(find.byType(AlertDialog), findsOneWidget);

        //expect the downloadChangelog button key to be present
        expect(find.byKey(Key("downloadChangelog")), findsOneWidget);

        //close the dialog
        await tester.tap(find.text("close"));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      });

  testWidgets("will color map icon by last modified date",
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    //find the iconbutton that opens the map background color
    //the colors are different for tiles so the color is changed
    final ListTile tile =
        find.byType(ListTile).first.evaluate().first.widget as ListTile;
    final trailingRow = tile.trailing as Row;
    final iconButton = trailingRow.children[0] as IconButton;
    //this should be yellow
    expect(iconButton.style!.backgroundColor!.resolve({})!.value, 4294967040);

    final ListTile tile2 =
        find.byType(ListTile).last.evaluate().last.widget as ListTile;
    final trailingRow2 = tile2.trailing as Row;
    final iconButton2 = trailingRow2.children[0] as IconButton;
    //this should be green
    expect(iconButton2.style!.backgroundColor!.resolve({})!.value, 4278255360);
  });
}
