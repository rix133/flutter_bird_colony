import 'package:excel/excel.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Measure toExcelRows and toExcelRowHeader', () {
    test('toExcelRows should return correct rows for numeric measure',
        () async {
      final measure = Measure(
        name: "Test Measure",
        value: "10",
        isNumber: true,
        unit: "kg",
        modified: DateTime.now(),
        type: "any",
        repeated: false,
      );

      final rows = measure.toExcelRow();
      expect((rows[0] as DoubleCellValue).value, double.parse(measure.value));
      expect((rows[1] as DateTimeCellValue).year, measure.modified.year);
      expect((rows[1] as DateTimeCellValue).month, measure.modified.month);
      expect((rows[1] as DateTimeCellValue).day, measure.modified.day);
    });

    test('toExcelRows should return correct rows for text measure', () async {
      final measure = Measure(
        name: "Test Measure",
        value: "Test Value",
        isNumber: false,
        unit: "kg",
        modified: DateTime.now(),
        type: "any",
        repeated: false,
      );

      final rows = measure.toExcelRow();
      expect((rows[0] as TextCellValue).value.text, measure.value);
      expect((rows[1] as DateTimeCellValue).year, measure.modified.year);
      expect((rows[1] as DateTimeCellValue).month, measure.modified.month);
      expect((rows[1] as DateTimeCellValue).day, measure.modified.day);
    });

    test('toExcelRowHeader should return correct headers', () {
      final measure = Measure(
        name: "Test Measure",
        value: "Test Value",
        isNumber: false,
        unit: "kg",
        modified: DateTime.now(),
        type: "any",
        repeated: false,
      );

      final headers = measure.toExcelRowHeader();
      expect(headers[0].value.text, measure.name + "_" + measure.unit);
      expect(headers[1].value.text, measure.name + '_time');
    });
  });
}
