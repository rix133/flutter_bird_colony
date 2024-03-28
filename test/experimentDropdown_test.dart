import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/experimentDropdown.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExperimentDropdown widget test', (WidgetTester tester) async {
    // Create a list of experiments
    final List<Experiment> experiments = [
      Experiment(
        id: "1",
        name: "Experiment 1",
        description: "Description 1",
        last_modified: DateTime.now(),
        responsible: "Responsible 1",
      ),
      Experiment(
        id: "2",
        name: "Experiment 2",
        description: "Description 2",
        last_modified: DateTime.now(),
        responsible: "Responsible 2",
      ),
    ];

    // Build the ExperimentDropdown widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExperimentDropdown(
            allExperiments: experiments,
            selectedExperiment: experiments[0].name,
            onChanged: (String? newValue) {},
          ),
        ),
      ),
    );
    // Verify the DropdownButton exists
    expect(find.byType(DropdownButton<String>), findsOneWidget);

// Verify the DropdownButton's value is the name of the first experiment
    DropdownButton<String> dropdownButton = tester.widget(find.byType(DropdownButton<String>));
    expect(dropdownButton.value, equals(experiments[0].name));

// Verify the DropdownButton has the correct number of items
    expect(dropdownButton.items?.length, equals(experiments.length));

  });
}