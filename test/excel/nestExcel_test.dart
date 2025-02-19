import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Nest toExcelRows and toExcelRowHeader', () {
    test('toExcelRows should return correct rows', () async {
      final nest = Nest(
        id: "123",
        discover_date: DateTime.now().subtract(Duration(days: 3)),
        last_modified: DateTime.now(),
        first_egg: DateTime.now().subtract(Duration(days: 2)),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );
      final firstApril = DateTime(DateTime.now().year, 4, 1);
      final rows = await nest.toExcelRows();
      expect((rows[0][0] as TextCellValue).value.text, nest.name);
      expect((rows[0][1] as DoubleCellValue).value, nest.getAccuracy());
      expect((rows[0][2] as DoubleCellValue).value, nest.coordinates.latitude);
      expect((rows[0][3] as DoubleCellValue).value, nest.coordinates.longitude);
      expect((rows[0][4] as TextCellValue).value.text, nest.species ?? "");
      expect((rows[0][6] as TextCellValue).value.text, nest.responsible ?? "");
      //cehck first egg date
      expect((rows[0][8] as DateCellValue).year, nest.first_egg!.year);
      expect((rows[0][8] as DateCellValue).month, nest.first_egg!.month);
      expect((rows[0][8] as DateCellValue).day, nest.first_egg!.day);
      expect((rows[0][9] as IntCellValue).value,
          nest.first_egg!.difference(firstApril).inDays + 1);
      expect((rows[0][10] as IntCellValue).value,
          DateTime.now().difference(nest.first_egg!).inDays);
      expect((rows[0][11] as IntCellValue).value,
          0); // no eggs as the egg is not in firestore
      expect((rows[0][12] as TextCellValue).value.text,
          nest.experiments?.map((e) => e.name).join(";\r") ?? "");
      expect((rows[0][13] as TextCellValue).value.text,
          nest.parents?.map((p) => p.name).join(";\r") ?? "");
      expect((rows[0][14] as IntCellValue).value, 0);
      expect((rows[0][15] as DoubleCellValue).value, 0.0);
    });

    test('toExcelRows should return correct first april days for other years',
        () async {
      final nest = Nest(
        id: "123",
        discover_date: DateTime(2022, 4, 4),
        last_modified: DateTime(2022, 7, 8),
        first_egg: DateTime(2022, 4, 6),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );

      final rows = await nest.toExcelRows();
      expect((rows[0][9] as IntCellValue).value, 6);
    });

    test('toExcelRowHeader should return correct headers', () {
      final nest = Nest(
        id: "123",
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );

      final headers = nest.toExcelRowHeader();
      expect(headers[0].value.text, 'name');
      expect(headers[1].value.text, 'accuracy');
      expect(headers[2].value.text, 'latitude');
      expect(headers[3].value.text, 'longitude');
      expect(headers[4].value.text, 'species');
      expect(headers[5].value.text, 'discover_date');
      expect(headers[6].value.text, 'last_modified_by');
      expect(headers[7].value.text, 'last_modified');
      expect(headers[8].value.text, 'first_egg_date');
      expect(headers[9].value.text, 'first_egg_days_since_1st_april');
      expect(headers[10].value.text, "days_since_first_egg");
      expect(headers[11].value.text, "egg_count");
      expect(headers[12].value.text, 'experiments');
      expect(headers[13].value.text, 'parents');
      expect(headers[14].value.text, "hatched_count");
      expect(headers[15].value.text, "total_eggs_mass");
    });
  });
}
