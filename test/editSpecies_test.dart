import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/screens/homepage.dart';
import 'package:flutter_bird_colony/screens/settings/editSpecies.dart';
import 'package:flutter_bird_colony/screens/settings/listSpecies.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'mocks/mockAuthService.dart';
import 'mocks/mockSharedPreferencesService.dart';

void main() {
  final authService = MockAuthService();
  final sharedPreferencesService = MockSharedPreferencesService();
  final firestore = FakeFirebaseFirestore();
  late Widget myApp;
  final userEmail = "test@example.com";
  Species species =
      Species(english: 'Common gull', local: 'Common gull', latinCode: 'CG');
  late CollectionReference speciesCollection;

  setUpAll(() async {
    //AuthService.instance = authService;
    speciesCollection =
        firestore.collection('settings').doc("default").collection("species");
    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});
  });

  getInitApp(dynamic args) {
    return ChangeNotifierProvider<SharedPreferencesService>(
      create: (_) => sharedPreferencesService,
      child: MaterialApp(
        initialRoute: '/editSpecies',
        onGenerateRoute: (settings) {
          if (settings.name == '/editSpecies') {
            return MaterialPageRoute(
              builder: (context) => EditSpecies(
                firestore: firestore,
              ),
              settings: RouteSettings(
                arguments: args, // get initial species from object
              ),
            );
          }
          if (settings.name == '/listSpecies') {
            return MaterialPageRoute(
              builder: (context) => ListSpecies(
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
  }

  setUp(() async {
    species.english = 'Common gull';
    species.local = 'Common gull';
    species.latinCode = 'CG';
    species.id = 'gc1';
    await speciesCollection.doc(species.id).set(species.toJson());
  });

  testWidgets("Will load edit species without arguments",
      (WidgetTester tester) async {
    myApp = await getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    expect(find.byType(EditSpecies), findsOneWidget);
  });

  testWidgets("Will load edit species with species",
      (WidgetTester tester) async {
    myApp = await getInitApp(species);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();
    expect(find.byType(EditSpecies), findsOneWidget);
  });

  testWidgets("Will save species", (WidgetTester tester) async {
    myApp = await getInitApp(species);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    //save the species
    await tester.tap(find.byKey(Key("saveButton")));
    await tester.pumpAndSettle();
    //expect to find the species in firestore
    var savedSpecies = await speciesCollection.doc(species.id).get();
    expect(savedSpecies.exists, true);
  });

  testWidgets("can delete species", (WidgetTester tester) async {
    myApp = await getInitApp(species);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text("Removing item"), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    //expect to not find the species in firestore
    var deletedSpecies = await speciesCollection.doc(species.id).get();
    expect(deletedSpecies.exists, false);
  });

  testWidgets("can cancel delete species", (WidgetTester tester) async {
    myApp = await getInitApp(species);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text("Removing item"), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    //expect to find the species in firestore
    var savedSpecies = await speciesCollection.doc(species.id).get();
    expect(savedSpecies.exists, true);
  });

  testWidgets("can edit species", (WidgetTester tester) async {
    myApp = await getInitApp(null);
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('English')), 'Common Gull');
    await tester.enterText(find.byKey(Key('Custom')), 'kalakajakas');
    await tester.enterText(find.byKey(Key('Latin')), 'Larus canus');
    await tester.pumpAndSettle();

    //save the species
    await tester.tap(find.byKey(Key("saveButton")));
    await tester.pumpAndSettle();
    //list all the documents in firestore
    var items = await speciesCollection.get();
    expect(items.docs.length, 2);
    //find the one with the new id and check the values
    items.docs.forEach((element) {
      if (element.id != species.id) {
        Species savedSpeciesData = Species.fromDocSnapshot(element);
        expect(savedSpeciesData.english, 'Common Gull');
        expect(savedSpeciesData.local, 'kalakajakas');
        expect(savedSpeciesData.latin, 'Larus canus');
      }
    });
  });
}
