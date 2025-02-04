import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Nest toExcelRows and toExcelRowHeader', () {
    test('toExcelRows should return correct rows', () async {
      final nest = Nest(
        id: "123",
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );
      final firstApril = DateTime(DateTime.now().year, 4, 1);
      final rows = await nest.toExcelRows();
      expect((rows[0][0] as TextCellValue).value, nest.name);
      expect((rows[0][1] as DoubleCellValue).value, nest.getAccuracy());
      expect((rows[0][2] as DoubleCellValue).value, nest.coordinates.latitude);
      expect((rows[0][3] as DoubleCellValue).value, nest.coordinates.longitude);
      expect((rows[0][4] as TextCellValue).value, nest.species ?? "");
      expect((rows[0][6] as TextCellValue).value, nest.responsible ?? "");
      expect(
          nest.first_egg != null ? (rows[0][8] as DateCellValue).year : "", "");
      expect((rows[0][9] as IntCellValue).value,
          firstApril.difference(nest.first_egg ?? DateTime(2200)).inDays);
      expect((rows[0][10] as IntCellValue).value,
          DateTime.now().difference(nest.first_egg ?? DateTime(2200)).inDays);
      expect((rows[0][11] as IntCellValue).value, 0);
      expect((rows[0][12] as TextCellValue).value,
          nest.experiments?.map((e) => e.name).join(";\r") ?? "");
      expect((rows[0][13] as TextCellValue).value,
          nest.parents?.map((p) => p.name).join(";\r") ?? "");
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
      expect(headers[0].value, 'name');
      expect(headers[1].value, 'accuracy');
      expect(headers[2].value, 'latitude');
      expect(headers[3].value, 'longitude');
      expect(headers[4].value, 'species');
      expect(headers[5].value, 'discover_date');
      expect(headers[6].value, 'last_modified_by');
      expect(headers[7].value, 'last_modified');
      expect(headers[8].value, 'first_egg_date');
      expect(headers[9].value, 'first_egg_days_since_1st_april');
      expect(headers[10].value, "days_since_first_egg");
      expect(headers[11].value, "egg_count");
      expect(headers[12].value, 'experiments');
      expect(headers[13].value, 'parents');
    });
  });
}
