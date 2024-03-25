import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/design/experimentDropdown.dart';
import 'package:kakrarahu/design/speciesRawAutocomplete.dart';
import 'package:kakrarahu/models/firestore/experiment.dart';
import 'package:kakrarahu/models/firestore/nest.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/screens/homepage.dart';
import 'package:kakrarahu/screens/nest/editNest.dart';
import 'package:kakrarahu/screens/nest/findNest.dart';
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
    coordinates: GeoPoint(0, 0),
    accuracy: "12.22m",
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

  setUpAll(() async {
    AuthService.instance = authService;
    LocationService.instance = locationAccuracy10;

    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});
    await firestore.collection('experiments').doc(experiment.id).set(experiment.toJson());
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
                arguments: {'nest_id': "1"}, // get initial nest from firestore
              ),
            );
          } else if (settings.name == '/findNest') {
            return MaterialPageRoute(
              builder: (context) => FindNest(
                firestore: firestore,
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
  });

  setUp(() async {
    //reset the database
    await firestore.collection('recent').doc("nest").set({"id": "1"});
    await nests
        .doc(nest.id)
        .set(nest.toJson());
  });

  testWidgets("Will display add egg and add parent buttons",
      (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    expect(find.text('add egg'), findsOneWidget);
    expect(find.text('add parent'), findsOneWidget);
  });

  testWidgets("Will display nest details", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    expect(find.text('~12.2m'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets("Will have unlisted species in nest details",
      (WidgetTester tester) async {
    await nests
        .doc(nest.id)
        .update({'species': 'test'});
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

    // Verify if the TextField's controller's text is "test"
    expect(textField.controller?.text, "test");
  });

  testWidgets("Will have listed species in nest details",
      (WidgetTester tester) async {
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


  testWidgets("Will display location button", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.my_location), findsOneWidget);
  });

  testWidgets("Will update nest location on button press", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    // Tap the location button
    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key("saveButton")));
    await tester.pumpAndSettle();
    
    

    // Verify if the nest's coordinates and accuracy are updated
    DocumentSnapshot nestDoc = await nests
        .doc(nest.id)
        .get();
    expect(nestDoc.get('coordinates'), isNotNull);
    expect(nestDoc.get('accuracy'), "5.00m");
  });
  

  testWidgets("Will add new egg on button press", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    // Tap the add egg button
    await tester.tap(find.byIcon(Icons.egg));
    await tester.pumpAndSettle();

    // Verify if a new egg is added to the nest
    QuerySnapshot eggSnapshot = await nests.doc(nest.id).collection("egg").get();
    expect(eggSnapshot.docs.length, equals(1));
  });

  testWidgets("Will display add experiment dialog", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    // Tap the add experiment button
    await tester.longPress(find.text("(long press to add experiment)"));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text("Add new experiment"), findsOneWidget);
  });

  testWidgets("Will add new experiment to nest", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    // Tap the add experiment button
    await tester.longPress(find.text("(long press to add experiment)"));
    await tester.pumpAndSettle();

    // Find the ExperimentDropdown widget
    final experimentDropdownFinder = find.byType(ExperimentDropdown);

// Ensure the ExperimentDropdown widget is in the widget tree
    expect(experimentDropdownFinder, findsOneWidget);

// Find the DropdownButton widget which is a descendant of the ExperimentDropdown widget
    final dropdownButtonFinder = find.descendant(
      of: experimentDropdownFinder,
      matching: find.byType(DropdownButton<String>),
    );

// Ensure the DropdownButton widget is in the widget tree
    expect(dropdownButtonFinder, findsOneWidget);

// Now you can interact with the DropdownButton widget in your test as needed
    //await tester.tap(dropdownButtonFinder);
    //await tester.pumpAndSettle();

    final dropdownButton = tester.widget<DropdownButton<String>>(dropdownButtonFinder);
    dropdownButton.onChanged != null ? dropdownButton.onChanged!('New Experiment') : null;
    await tester.pumpAndSettle();
    // Wait for the tap action to complete

    // Tap the "Add" button
    await tester.tap(find.text("Add"));
    await tester.pumpAndSettle();

    // Verify if the new experiment is added to the nest
    DocumentSnapshot nestDoc = await nests
        .doc(nest.id)
        .get();
    expect(nestDoc.get('experiments'), isNotEmpty);

    DocumentSnapshot experimentDoc = await firestore
        .collection('experiments')
        .doc(experiment.id)
        .get();
    expect(experimentDoc.get('nests'), [nest.id]);

  });


  testWidgets("Will update nest species", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

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


    // Enter a new species name into the TextField
    await tester.enterText(textFieldFinder, "Arctic tern");
    await tester.pumpAndSettle();
    expect(textField.controller?.text, "Arctic tern");

    // Simulate the submission of the TextField
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Tap the "save" button
    await tester.tap(find.byKey(Key("saveButton")));
    await tester.pumpAndSettle();

    // Verify if the nest's species is updated
    DocumentSnapshot nestDoc = await nests
        .doc(nest.id)
        .get();
    expect(nestDoc.get('species'), "Arctic tern");
  });

  testWidgets("Will update nest note measure", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    // Find the Note input widget


  //find first empty textfield
    Finder textFormFieldFinder = find.byElementPredicate((element) {
      if (element.widget is TextFormField) {
        TextFormField textField = element.widget as TextFormField;
        return textField.controller?.text == "";
      }
      return false;
    });


    // Enter a note into the TextFormField
    await tester.enterText(textFormFieldFinder, "New Note");
    await tester.pumpAndSettle();

    // Tap the "save" button
    await tester.tap(find.byKey(Key("saveButton")));
    await tester.pumpAndSettle();

    // Verify if the nest's measures are updated
    DocumentSnapshot nestDoc = await nests
        .doc(nest.id)
        .get();
    expect(nestDoc.get('measures'), isNotEmpty);
  });

  testWidgets("Will update nest responsible", (WidgetTester tester) async {
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    // Tap the "save" button
    await tester.tap(find.byKey(Key("saveButton")));
    await tester.pumpAndSettle();

    // Verify if the nest's responsible is updated
    DocumentSnapshot nestDoc = await nests
        .doc(nest.id)
        .get();
    expect(nestDoc.get('responsible'), "Test User");
  });
}
