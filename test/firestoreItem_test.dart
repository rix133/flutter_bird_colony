import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/models/firestore/bird.dart';
import 'package:kakrarahu/models/firestore/egg.dart';
import 'package:kakrarahu/models/firestore/experiment.dart';
import 'package:kakrarahu/models/firestore/nest.dart';
import 'package:kakrarahu/models/firestoreItemMixin.dart';
import 'package:kakrarahu/models/measure.dart';

void main() {
  group('FSItemMixin', () {
    late FSItemMixin fsItemMixin;
    final Nest nest1 = Nest(
      id: "1",
      coordinates: GeoPoint(0, 0),
      accuracy: "12.22m",
      last_modified: DateTime.now().subtract(Duration(days: 2)),
      discover_date: DateTime.now().subtract(Duration(days: 2)),
      first_egg: DateTime.now().subtract(Duration(days: 2)),
      responsible: "Admin",
      species: "Common gull",
      measures: [Measure.note()],
    );

    final Egg egg = Egg(
        id: "1 egg 1",
        discover_date: DateTime.now().subtract(Duration(days: 2)),
        responsible: "Admin",
        ring: null,
        last_modified: DateTime.now().subtract(Duration(days: 1)),
        status: "intact",
        measures: [Measure.note()]);
    final Experiment experiment = Experiment(
      id: "1",
      name: "New Experiment",
      description: "Test experiment",
      last_modified: DateTime.now(),
      created: DateTime.now(),
      year: DateTime.now().year,
      responsible: "Admin",
    );

    final parent = Bird(
        ringed_date: DateTime(2023, 6, 1),
        band: 'AA1234',
        ringed_as_chick: true,
        measures: [Measure.note()],
        nest: "234",
        //2022 was the nest
        nest_year: 2023,
        responsible: 'Admin',
        last_modified: DateTime(2023, 6, 1),
        species: 'Common gull');

    final chick = Bird(
        ringed_date: DateTime.now().subtract(Duration(days: 3)),
        band: 'AA1235',
        ringed_as_chick: true,
        measures: [],
        nest: "1",
        //3 years ago this was the nest
        nest_year: DateTime.now().year,
        responsible: 'Admin',
        last_modified: DateTime.now().subtract(Duration(days: 3)),
        species: 'Common gull');

    setUp(() {
      fsItemMixin = FSItemMixin();
    });

    test('createSortedData_emptyList_returnsEmptyData', () async {
      var result = await fsItemMixin.createSortedData([]);

      expect(result['start'], null);
      expect(result['end'], null);
      expect(result['sortedData'], isEmpty);
    });

    test('createSortedData_singleItem_returnsSortedData', () async {
      var result = await fsItemMixin.createSortedData([nest1]);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);

      result = await fsItemMixin.createSortedData([egg]);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);

      result = await fsItemMixin.createSortedData([experiment]);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);
    });

    test("createSortedData from bird returnsSortedData", () async {
      var result = await fsItemMixin.createSortedData([parent]);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);

      result = await fsItemMixin.createSortedData([chick]);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);
    });

    test("createSortedData from birds returnsSortedData", () async {
      var result = await fsItemMixin.createSortedData([parent, chick]);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);
    });

    test('createSortedData_multipleItems_returnsSortedData', () async {
      var result = await fsItemMixin.createSortedData([nest1, nest1]);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);

      result = await fsItemMixin.createSortedData([egg, egg]);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);

      result = await fsItemMixin.createSortedData([experiment, experiment]);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);
    });
  });
}
