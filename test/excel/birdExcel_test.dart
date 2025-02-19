import 'package:excel/excel.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bird toExcelRows and toExcelRowHeader', () {
    test('toExcelRows should return correct rows', () async {
      final bird = Bird(
        band: "123",
        ringed_date: DateTime.now(),
        ringed_as_chick: true,
        measures: [],
      );

      final rows = await bird.toExcelRows();
      expect((rows[0][0] as TextCellValue).value.text, bird.band);
      expect((rows[0][1] as TextCellValue).value.text, bird.color_band ?? "");
      expect((rows[0][2] as TextCellValue).value.text, bird.getType());
      expect((rows[0][3] as TextCellValue).value.text, bird.nest ?? "");
      expect((rows[0][4] as IntCellValue).value, bird.nest_year ?? 0);
      expect((rows[0][5] as IntCellValue).value, bird.ageInYears());
      expect((rows[0][6] as TextCellValue).value.text, bird.responsible ?? "");
      expect((rows[0][7] as TextCellValue).value.text, bird.species ?? "");
      expect((rows[0][8] as DateCellValue).year, bird.ringed_date.year);
      expect((rows[0][8] as DateCellValue).month, bird.ringed_date.month);
      expect((rows[0][8] as DateCellValue).day, bird.ringed_date.day);
      expect((rows[0][9] as BoolCellValue).value, bird.ringed_as_chick);
      expect((rows[0][10] as TextCellValue).value.text,
          bird.last_modified?.toIso8601String() ?? "");
      expect((rows[0][11] as TextCellValue).value.text, bird.egg ?? "");
    });

    test('toExcelRowHeader should return correct headers', () {
      final bird = Bird(
        band: "123",
        ringed_date: DateTime.now(),
        ringed_as_chick: true,
        measures: [],
      );

      final headers = bird.toExcelRowHeader();
      expect(headers[0].value.text, 'band');
      expect(headers[1].value.text, 'color_band');
      expect(headers[2].value.text, 'type');
      expect(headers[3].value.text, 'nest');
      expect(headers[4].value.text, 'nest_year');
      expect(headers[5].value.text, 'age_years');
      expect(headers[6].value.text, 'responsible');
      expect(headers[7].value.text, 'species');
      expect(headers[8].value.text, 'ringed_date');
      expect(headers[9].value.text, 'ringed_as_chick');
      expect(headers[10].value.text, 'last_modified');
      expect(headers[11].value.text, 'egg');
    });
  });
}
