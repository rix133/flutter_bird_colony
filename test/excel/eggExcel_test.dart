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
      expect((rows[0][0] as TextCellValue).value, egg.getNest() ?? "");
      expect((rows[0][1] as TextCellValue).value, egg.getNr() ?? "");
      expect((rows[0][2] as TextCellValue).value, egg.type() ?? "");
      expect((rows[0][3] as DateCellValue).year, egg.discover_date.year);
      expect((rows[0][3] as DateCellValue).month, egg.discover_date.month);
      expect((rows[0][3] as DateCellValue).day, egg.discover_date.day);
      expect((rows[0][4] as TextCellValue).value, egg.responsible ?? "");
      expect((rows[0][5] as TextCellValue).value,
          egg.last_modified?.toIso8601String() ?? "");
      expect((rows[0][6] as TextCellValue).value, egg.ring ?? "");
      expect((rows[0][7] as TextCellValue).value, egg.status.toString());
      expect((rows[0][8] as TextCellValue).value,
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
      expect(headers[0].value, 'nest');
      expect(headers[1].value, 'egg_nr');
      expect(headers[2].value, 'type');
      expect(headers[3].value, 'discover_date');
      expect(headers[4].value, 'last_checked_by');
      expect(headers[5].value, 'last_checked');
      expect(headers[6].value, 'ring');
      expect(headers[7].value, 'status');
      expect(headers[8].value, 'experiments');
    });
  });
}
