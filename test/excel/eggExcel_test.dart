import 'package:excel/excel.dart';
import 'package:flutter_bird_colony/models/eggStatus.dart';
import 'package:flutter_bird_colony/models/firestore/egg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Egg toExcelRows and toExcelRowHeader', () {
    test('toExcelRows should return correct rows', () async {
      final egg = Egg(
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('intact'),
        measures: [],
      );

      final rows = await egg.toExcelRows();
      expect((rows[0][0] as TextCellValue).value.text, egg.getNest() ?? "");
      expect((rows[0][1] as TextCellValue).value.text, egg.getNr() ?? "");
      expect((rows[0][2] as TextCellValue).value.text, egg.type() ?? "");
      expect((rows[0][3] as DateCellValue).year, egg.discover_date.year);
      expect((rows[0][3] as DateCellValue).month, egg.discover_date.month);
      expect((rows[0][3] as DateCellValue).day, egg.discover_date.day);
      expect((rows[0][4] as TextCellValue).value.text, egg.responsible ?? "");
      expect((rows[0][5] as TextCellValue).value.text,
          egg.last_modified?.toIso8601String() ?? "");
      expect((rows[0][6] as TextCellValue).value.text, egg.ring ?? "");
      expect((rows[0][7] as TextCellValue).value.text, egg.status.toString());
      expect((rows[0][8] as TextCellValue).value.text,
          egg.experiments?.map((e) => e.name).join(";\r") ?? "");
    });

    test('toExcelRowHeader should return correct headers', () {
      final egg = Egg(
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('intact'),
        measures: [],
      );

      final headers = egg.toExcelRowHeader();
      expect(headers[0].value.text, 'nest');
      expect(headers[1].value.text, 'egg_nr');
      expect(headers[2].value.text, 'type');
      expect(headers[3].value.text, 'discover_date');
      expect(headers[4].value.text, 'last_checked_by');
      expect(headers[5].value.text, 'last_checked');
      expect(headers[6].value.text, 'ring');
      expect(headers[7].value.text, 'status');
      expect(headers[8].value.text, 'experiments');
    });
  });
}
