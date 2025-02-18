import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_bird_colony/models/eggStatus.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/models/firestore/egg.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/firestore/firestoreItem.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/firestoreItemMixin.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final firestore = FakeFirebaseFirestore();

  final Nest nest1 = Nest(
    id: "1",
    coordinates: GeoPoint(0, 0),
    accuracy: "3.22m",
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
      status: EggStatus('intact'),
      measures: [Measure.note()]);

  final Egg egg_nest2 = Egg(
      id: "2 egg 1",
      discover_date: DateTime.now().subtract(Duration(days: 2)),
      responsible: "Admin",
      ring: null,
      last_modified: DateTime.now().subtract(Duration(days: 1)),
      status: EggStatus('intact'),
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
      egg: "1",
      ringed_as_chick: true,
      measures: [],
      nest: "1",
      //3 years ago this was the nest
      nest_year: DateTime.now().year,
      responsible: 'Admin',
      last_modified: DateTime.now().subtract(Duration(days: 3)),
      species: 'Common gull');
  group('FSItemMixin', () {
    late FSItemMixin fsItemMixin;

    setUpAll(() async {
      await nest1.save(firestore);
      await egg.save(firestore);
      await egg_nest2.save(firestore);
      await experiment.save(firestore);
      await parent.save(firestore);
      await chick.save(firestore);

      fsItemMixin = FSItemMixin();
    });

    test('createSortedData_emptyList_returnsEmptyData', () async {
      var result = await fsItemMixin.createSortedData([], firestore);

      expect(result['start'], null);
      expect(result['end'], null);
      expect(result['sortedData'], isEmpty);
      expect(result['otherItems'], isEmpty);
    });

    test('createSortedData_singleItem_returnsSortedData', () async {
      var result = await fsItemMixin.createSortedData([nest1], firestore);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);
      expect(result['otherItems'], isNotEmpty);

      result = await fsItemMixin.createSortedData([egg], firestore);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);
      expect(result['otherItems'], isEmpty);

      result = await fsItemMixin.createSortedData([experiment], firestore);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);
      expect(result['otherItems'], isEmpty);
    });

    test("createSortedData from bird returnsSortedData", () async {
      var result = await fsItemMixin.createSortedData([parent], firestore);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);
      expect(result['otherItems'], isEmpty);

      result = await fsItemMixin.createSortedData([chick], firestore);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);
      expect(result['otherItems'], isNotEmpty);
    });

    test("createSortedData from birds returnsSortedData", () async {
      var result =
          await fsItemMixin.createSortedData([parent, chick], firestore);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);
      expect(result['otherItems'], isNotEmpty);
    });

    test('createSortedData_multipleItems_returnsSortedData', () async {
      var result =
          await fsItemMixin.createSortedData([nest1, nest1], firestore);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);
      expect(result['otherItems'], isNotEmpty);

      result = await fsItemMixin.createSortedData([egg, egg], firestore);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);
      expect(result['otherItems'], isEmpty);

      result = await fsItemMixin
          .createSortedData([experiment, experiment], firestore);

      expect(result['start'], isNotNull);
      expect(result['end'], isNotNull);
      expect(result['sortedData'], isNotEmpty);
      expect(result['otherItems'], isEmpty);
    });
  });

  group('Excel download', () {
    setUpAll(() async {
      await nest1.save(firestore);
      await egg.save(firestore);
      await egg_nest2.save(firestore);
      await experiment.save(firestore);
      await parent.save(firestore);
      await chick.save(firestore);
    });
    final mixin = FSItemMixin();

    test(
        'downloadExcel returns sheets when test is true and type is experiments',
        () async {
      final items = <Experiment>[experiment];
      final result = await mixin.downloadExcel(items, 'experiments', firestore,
          test: true);
      expect(result, isNotNull);
      expect(result, isA<List<List<List<CellValue>>>>());
    });

    test('downloadExcel returns sheets when test is true and type is nests',
        () async {
      final items = <Nest>[nest1];
      final result =
          await mixin.downloadExcel(items, 'nests', firestore, test: true);
      expect(result, isNotNull);
      expect(result, isA<List<List<List<CellValue>>>>());
      //expect the result to have nest and egg sheets
      expect(result!.length, 2);
      expect(result[0], isNotNull);
      expect(result[1], isNotNull);
    });

    test(
        'downloadExcel returns only related eggs when test is true and type is nests',
        () async {
      final items = <Nest>[nest1];
      final result =
          await mixin.downloadExcel(items, 'nests', firestore, test: true);
      expect(result, isNotNull);
      expect(result, isA<List<List<List<CellValue>>>>());
      //expect the result to have nest and egg sheets
      expect(result!.length, 2);
      expect(result[0], isNotNull);
      expect(result[1], isNotNull);
      expect(result[1].length, 2); //only header and one egg
    });

    test('downloadExcel returns nests with correct egg count', () async {
      final items = <Nest>[nest1];
      final result =
          await mixin.downloadExcel(items, 'nests', firestore, test: true);
      expect(result, isNotNull);
      expect(result, isA<List<List<List<CellValue>>>>());
      //expect the result to have nest and egg sheets
      expect(result!.length, 2);
      expect(result[0], isNotNull);
      expect(result[0].length, 2); //only header and one nest

      List<CellValue> nestRow = result[0][1]; //nest data row
      //cehck that nestrow has 16 items
      expect(nestRow.length, 16);
      //check that the egg count is correct (1)
      expect(nestRow[11], isA<IntCellValue>());
      expect((nestRow[11] as IntCellValue).value, 1);
    });

    test('downloadExcel returns sheets when test is true and type is bird',
        () async {
      final items = <FirestoreItem>[parent, chick];
      final result =
          await mixin.downloadExcel(items, 'birds', firestore, test: true);
      expect(result, isNotNull);
      expect(result, isA<List<List<List<CellValue>>>>());
    });

    test('downloadExcel handles empty FirestoreItem list when test is false',
        () async {
      final items = <FirestoreItem>[];
      final result = await mixin.downloadExcel(items, 'experiments', firestore,
          test: false);
      expect(result, isNull);
    });

    test('returns Excel object when testOnly is true from saveExcel', () async {
      // Arrange
      FSItemMixin mixin = FSItemMixin();
      List<List<List<CellValue>>> sheets = [
        [
          [TextCellValue('Header1'), TextCellValue('Header2')],
          [TextCellValue('Data1'), TextCellValue('Data2')]
        ]
      ];
      List<String> types = ['TestType'];

      // Act
      var result = await mixin.saveAsExcel(sheets, types, testOnly: true);

      // Assert
      expect(result, isA<Excel>());
      expect(result['TestType'], isNotNull);
    });
  });

  group('Changelog download', () {
    setUpAll(() async {
      await nest1.save(firestore);
      await egg.save(firestore);
      await experiment.save(firestore);
      await parent.save(firestore);
      await chick.save(firestore);
    });
    final mixin = FSItemMixin();

    test(
        'downloadChangeLog returns sheets when test is true and type is experiments',
        () async {
      final result = await mixin.downloadChangeLog(
          experiment.changeLog(firestore), 'experiments', firestore,
          test: true);
      expect(result, isNotNull);
      expect(result, isA<List<List<List<CellValue>>>>());
    });

    test('downloadChangeLog returns sheets when test is true and type is nests',
        () async {
      final result = await mixin.downloadChangeLog(
          nest1.changeLog(firestore), 'nests', firestore,
          test: true);
      expect(result, isNotNull);
      expect(result, isA<List<List<List<CellValue>>>>());
    });

    test('downloadChangeLog returns sheets when test is true and type is birds',
        () async {
      final result = await mixin.downloadChangeLog(
          chick.changeLog(firestore), 'birds', firestore,
          test: true);
      expect(result, isNotNull);
      expect(result, isA<List<List<List<CellValue>>>>());
    });
  });
}
