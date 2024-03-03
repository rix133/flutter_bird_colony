import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/screens/nest/editEgg.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

import 'mocks/mockSharedPreferencesService.dart';


void main() {

  final sharedPreferencesService = MockSharedPreferencesService();
  final firestore = FakeFirebaseFirestore();
  late Widget myApp;
  final userEmail = "test@example.com";

  setUpAll(() async {
    await firestore.collection('users').doc(userEmail).set({'isAdmin': false});
    myApp = ChangeNotifierProvider<SharedPreferencesService>(
        create: (_) => sharedPreferencesService,
        child: MaterialApp(home: EditEgg(firestore: firestore)));
  });

  testWidgets('Test RawAutocomplete widget', (WidgetTester tester) async {
    // Build the EditEgg widget
    await tester.pumpWidget(myApp);
    await tester.pumpAndSettle();

    // Find the RawAutocomplete widget
    Finder rawAutocompleteFinder = find.byType(RawAutocomplete);

// Find the TextField widget which is a descendant of the RawAutocomplete widget
    Finder textFieldFinder = find.descendant(
      of: rawAutocompleteFinder,
      matching: find.byType(TextField),
    );

    expect(textFieldFinder, findsOneWidget);

    // Enter text into the TextField widget
    await tester.enterText(textFieldFinder, 'intact');

    // Rebuild the widget tree and allow the autocomplete options to appear
    await tester.pumpAndSettle();

    // Find the ListTile widget that represents the autocomplete option
    Finder listTileFinder = find.widgetWithText(ListTile, 'intact');
    expect(listTileFinder, findsOneWidget);

    // Tap on the ListTile widget
    await tester.tap(listTileFinder);

    // Rebuild the widget tree to reflect the changes
    await tester.pumpAndSettle();

    // Verify that the TextField's text has been updated
    TextField textField = tester.widget(textFieldFinder);
    expect(textField.controller?.text, 'intact');
  });
}