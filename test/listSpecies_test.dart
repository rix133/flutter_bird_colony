import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/screens/settings/editSpecies.dart';
import 'package:flutter_bird_colony/screens/settings/listSpecies.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'mocks/mockSharedPreferencesService.dart';

void main() {
  final firestore = FakeFirebaseFirestore();
  final sharedPreferencesService = MockSharedPreferencesService();
  late Widget myApp;

  final species1 = Species(
    english: 'Common Gull',
    local: 'Gull',
    latinCode: 'CG',
  );

  final species2 = Species(
    english: 'European Herring Gull',
    local: 'Gull',
    latinCode: 'EHG',
  );

  setUpAll(() async {
    await firestore
        .collection('settings')
        .doc('default')
        .collection("species")
        .doc('1')
        .set(species1.toJson());
    await firestore
        .collection('settings')
        .doc('default')
        .collection("species")
        .doc('2')
        .set(species2.toJson());

    myApp = ChangeNotifierProvider<SharedPreferencesService>(
        create: (_) => sharedPreferencesService,
        child: MaterialApp(home: ListSpecies(firestore: firestore), routes: {
          '/editSpecies': (context) => EditSpecies(firestore: firestore),
        }));
  });

  group('ListSpecies', () {
    testWidgets('displays species in a list', (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      expect(find.text('Common Gull'), findsOneWidget);
      expect(find.text('European Herring Gull'), findsOneWidget);
    });

    testWidgets('navigates to edit species on tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Common');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      expect(find.byType(EditSpecies), findsOneWidget);
    });

    testWidgets('filters species by name', (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Common');
      await tester.pumpAndSettle();

      expect(find.text('Common Gull'), findsOneWidget);
      expect(find.text('European Herring Gull'), findsNothing);
    });

    testWidgets('opens closes filter dialog', (WidgetTester tester) async {
      await tester.pumpWidget(myApp);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.filter_alt));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Close'), findsNothing);
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
  });
}
