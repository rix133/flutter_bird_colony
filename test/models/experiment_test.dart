import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/utils/year.dart';
import 'package:flutter_test/flutter_test.dart';

Nest _testNest(String id, int year, {List<Experiment>? experiments}) {
  return Nest(
      id: id,
      discover_date: DateTime(year, 1, 1),
      last_modified: DateTime(year, 1, 2),
      accuracy: 'test',
      coordinates: GeoPoint(0, 0),
      responsible: 'tester',
      species: 'test',
      experiments: experiments,
      measures: []);
}

Experiment _testExperiment(int year, {List<String> nests = const ['1']}) {
  return Experiment(
      id: 'exp1',
      name: 'Existing experiment',
      year: year,
      nests: List.from(nests),
      birds: [],
      measures: [],
      color: Colors.blue,
      last_modified: DateTime(year, 1, 3),
      created: DateTime(year, 1, 1));
}

void main() {
  test("saving an added nest only refreshes the added nest", () async {
    final firestore = FakeFirebaseFirestore();
    final year = DateTime.now().year;
    final nestCollection = firestore.collection(yearToNestCollectionName(year));
    final experiment = _testExperiment(year);

    await firestore
        .collection('experiments')
        .doc(experiment.id)
        .set(experiment.toJson());

    final existingNest = _testNest('1', year);
    final existingNestJson = existingNest.toJson();
    existingNestJson['experiments'] = [
      Map<String, dynamic>.from(experiment.toSimpleJson())
        ..['sentinel'] = 'unchanged'
    ];
    await nestCollection.doc('1').set(existingNestJson);
    await nestCollection.doc('2').set(_testNest('2', year).toJson());

    final loadedExperiment = Experiment.fromDocSnapshot(
        await firestore.collection('experiments').doc(experiment.id).get());
    loadedExperiment.nests!.add('2');

    final result = await loadedExperiment.save(firestore);

    expect(result.success, true);
    final existingNestData = (await nestCollection.doc('1').get()).data()!;
    final existingExperimentMarker = Map<String, dynamic>.from(
        (existingNestData['experiments'] as List<dynamic>).first as Map);
    expect(existingExperimentMarker['sentinel'], 'unchanged');

    final addedNest = Nest.fromDocSnapshot(await nestCollection.doc('2').get());
    expect(addedNest.experiments?.map((e) => e.id), contains('exp1'));

    final experimentData =
        (await firestore.collection('experiments').doc('exp1').get()).data()!;
    expect(experimentData['nests'], ['1', '2']);
  });

  test("saving changed experiment marker refreshes existing nests", () async {
    final firestore = FakeFirebaseFirestore();
    final year = DateTime.now().year;
    final nestCollection = firestore.collection(yearToNestCollectionName(year));
    final experiment = _testExperiment(year);

    await firestore
        .collection('experiments')
        .doc(experiment.id)
        .set(experiment.toJson());
    await nestCollection
        .doc('1')
        .set(_testNest('1', year, experiments: [experiment]).toJson());

    final loadedExperiment = Experiment.fromDocSnapshot(
        await firestore.collection('experiments').doc(experiment.id).get());
    loadedExperiment.name = 'Renamed experiment';

    final result = await loadedExperiment.save(firestore);

    expect(result.success, true);
    final updatedNest =
        Nest.fromDocSnapshot(await nestCollection.doc('1').get());
    expect(updatedNest.experiments?.single.name, 'Renamed experiment');
  });

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
