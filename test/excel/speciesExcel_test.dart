import 'package:excel/excel.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Species', () {
    test('toExcelRowHeader should return correct headers', () {
      final species = Species(
        english: 'Test English',
        local: 'Test Local',
        latin: 'Test Latin',
        latinCode: 'T',
        responsible: 'Test Responsible',
        letters: 'Test Letters',
      );

      final headers = species.toExcelRowHeader();
      expect(headers[0].value.text, 'English');
      expect(headers[1].value.text, 'Local');
      expect(headers[2].value.text, 'Latin');
      expect(headers[3].value.text, 'Latin Code');
      expect(headers[4].value.text, 'Responsible');
      expect(headers[5].value.text, 'Letters');
      expect(headers[6].value.text, 'Last Modified');
    });

    test('toExcelRows should return correct rows', () async {
      final species = Species(
        english: 'Test English',
        local: 'Test Local',
        latin: 'Test Latin',
        latinCode: 'T',
        responsible: 'Test Responsible',
        letters: 'Test Letters',
        last_modified: DateTime.now(),
      );

      final rows = await species.toExcelRows();
      expect((rows[0][0] as TextCellValue).value.text, species.english);
      expect((rows[0][1] as TextCellValue).value.text, species.local);
      expect((rows[0][2] as TextCellValue).value.text, species.latin ?? '');
      expect((rows[0][3] as TextCellValue).value.text, species.latinCode);
      expect(
          (rows[0][4] as TextCellValue).value.text, species.responsible ?? '');
      expect((rows[0][5] as TextCellValue).value.text, species.letters);
      expect(
          (rows[0][6] as DateTimeCellValue).year, species.last_modified?.year);
      expect((rows[0][6] as DateTimeCellValue).month,
          species.last_modified?.month);
      expect((rows[0][6] as DateTimeCellValue).day, species.last_modified?.day);
    });
  });
}
