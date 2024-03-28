import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/speciesRawAutocomplete.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_test/flutter_test.dart';

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
    final textFieldFinder = find.byType(TextField);

    // Use the `find` method to locate the TextField in the widget tree.
    TextField textField = tester.widget(textFieldFinder);

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
    final textFieldFinder = find.byType(TextField);

    //enter test in the textfield
    await tester.enterText(textFieldFinder, 'te');
    await tester.pumpAndSettle();

    //tap the first listtile
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    //check that the textfield reads "test"
    TextField textField = tester.widget(textFieldFinder);
    expect(textField.controller?.text, 'test');
  });


}