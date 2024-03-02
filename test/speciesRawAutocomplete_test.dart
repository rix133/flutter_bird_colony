import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/design/speciesRawAutocomplete.dart';
import 'package:kakrarahu/models/firestore/species.dart';

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
}