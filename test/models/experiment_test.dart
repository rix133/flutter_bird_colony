import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("experiment list tile shows nest IDs for short lists",
      (WidgetTester tester) async {
    final experiment = Experiment(
      id: "short_experiment",
      name: "Short Experiment",
      year: DateTime.now().year,
      nests: ["1", "2", "3", "4", "5", "6", "7"],
      last_modified: DateTime.now(),
      created: DateTime.now(),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) =>
              experiment.getListTile(context, FakeFirebaseFirestore()),
        ),
      ),
    ));

    expect(find.text("Nests: 1, 2, 3, 4, 5, 6, 7"), findsOneWidget);
  });

  testWidgets("experiment list tile shows nest count for long lists",
      (WidgetTester tester) async {
    final experiment = Experiment(
      id: "long_experiment",
      name: "Long Experiment",
      year: DateTime.now().year,
      nests: ["1", "2", "3", "4", "5", "6", "7", "8"],
      last_modified: DateTime.now(),
      created: DateTime.now(),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) =>
              experiment.getListTile(context, FakeFirebaseFirestore()),
        ),
      ),
    ));

    expect(find.text("Nests: 8 nests"), findsOneWidget);
    expect(find.textContaining("Nests: 1, 2, 3"), findsNothing);
  });
}
