import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/speciesRawAutocomplete.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'mocks/mocSharedPreferences.dart';

void main() {
  testWidgets('SpeciesRawAutocomplete displays "test" in its controller', (WidgetTester tester) async {
    // Create the widget by telling the tester to build it.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body:SpeciesRawAutocomplete(
        species: Species(english: 'test', local: '', latinCode: ''),
        returnFun: (Species s) {},
        speciesList: LocalSpeciesList(),
      ),
    )));

    // Create the Finders.
    final textFieldFinder = find.byType(TextFormField);

    // Use the `find` method to locate the TextField in the widget tree.
    TextFormField textField = tester.widget(textFieldFinder);

    // Verify if the TextField's controller's text is "test".
    expect(textField.controller?.text, 'test');
  });

  testWidgets("SpeciesRawAutocomplete calls returnFun when a species is selected", (WidgetTester tester) async {
    // Create the widget by telling the tester to build it.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body:SpeciesRawAutocomplete(
        species: Species(english: '', local: '', latinCode: ''),
        returnFun: (Species s) {},
        speciesList: LocalSpeciesList.fromStringList(["test","joke"]),
      ),
    )));

    // Create the Finders.
    final textFieldFinder = find.byType(TextFormField);

    //enter test in the textfield
    await tester.enterText(textFieldFinder, 'te');
    await tester.pumpAndSettle();

    //tap the first listtile
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    //check that the textfield reads "test"
    TextFormField textField = tester.widget(textFieldFinder);
    expect(textField.controller?.text, 'test');
  });

  testWidgets('SpeciesRawAutocomplete shows local name when language is local', (WidgetTester tester) async {
    final sharedPreferences = MockSharedPreferences();
    final sps = SharedPreferencesService(sharedPreferences);
    sps.speciesNameLanguage = SpeciesNameLanguage.local;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: sps,
        child: MaterialApp(
          home: Scaffold(
            body: SpeciesRawAutocomplete(
              species: Species(english: 'EnglishName', local: 'LocalName', latinCode: ''),
              returnFun: (Species s) {},
              speciesList: LocalSpeciesList.fromSpeciesList([
                Species(english: 'EnglishName', local: 'LocalName', latinCode: ''),
              ]),
            ),
          ),
        ),
      ),
    );

    final textFieldFinder = find.byType(TextFormField);
    TextFormField textField = tester.widget(textFieldFinder);
    expect(textField.controller?.text, 'LocalName');

    await tester.enterText(textFieldFinder, 'Lo');
    await tester.pumpAndSettle();

    expect(find.text('LocalName'), findsWidgets);
    expect(find.text('EnglishName'), findsWidgets);
  });

}
