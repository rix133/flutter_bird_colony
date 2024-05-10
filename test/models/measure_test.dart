import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Measure class tests', () {
    test('Measure copy should return a new instance with same values', () {
      final measure = Measure(
        name: 'test',
        value: '10',
        isNumber: true,
        unit: 'kg',
        modified: DateTime.now(),
        type: 'any',
      );

      final copiedMeasure = measure.copy();

      expect(copiedMeasure.name, equals(measure.name));
      expect(copiedMeasure.value, equals(measure.value));
      expect(copiedMeasure.isNumber, equals(measure.isNumber));
      expect(copiedMeasure.unit, equals(measure.unit));
      expect(copiedMeasure.modified, equals(measure.modified));
      expect(copiedMeasure.type, equals(measure.type));
    });

    test(
        'Measure isInvalid should return true when required and value is empty',
        () {
      final measure = Measure(
        name: 'test',
        value: '',
        isNumber: true,
        unit: 'kg',
        modified: DateTime.now(),
        type: 'any',
        required: true,
      );

      expect(measure.isInvalid(), true);
    });

    test(
        'Measure isInvalid should return false when not required and value is empty',
        () {
      final measure = Measure(
        name: 'test',
        value: '',
        isNumber: true,
        unit: 'kg',
        modified: DateTime.now(),
        type: 'any',
        required: false,
      );

      expect(measure.isInvalid(), false);
    });

    test(
        'Measure isInvalid should return false when required and value is not empty',
        () {
      final measure = Measure(
        name: 'test',
        value: '10',
        isNumber: true,
        unit: 'kg',
        modified: DateTime.now(),
        type: 'any',
        required: true,
      );

      expect(measure.isInvalid(), false);
    });
  });

  group("numeric factory tests", () {
    test(
        'Measure numeric factory should return a new instance with isNumber true',
        () {
      final measure = Measure.numeric(name: 'test', value: '10', unit: 'kg');

      expect(measure.name, equals('test'));
      expect(measure.value, equals('10'));
      expect(measure.isNumber, equals(true));
      expect(measure.unit, equals('kg'));
      expect(measure.type, equals('any'));
      expect(measure.required, equals(false));
    });

    test(
        'Measure numeric factory should return a new instance with required true',
        () {
      final measure = Measure.numeric(
          name: 'test', value: '10', unit: 'kg', required: true);

      expect(measure.name, equals('test'));
      expect(measure.value, equals('10'));
      expect(measure.isNumber, equals(true));
      expect(measure.unit, equals('kg'));
      expect(measure.type, equals('any'));
      expect(measure.required, equals(true));
    });
  });
  group('Measure.text factory tests', () {
    test(
        'Measure.text factory should return a new instance with isNumber false',
        () {
      final measure = Measure.text(name: 'test', value: '10', unit: 'kg');

      expect(measure.name, equals('test'));
      expect(measure.value, equals('10'));
      expect(measure.isNumber, equals(false));
      expect(measure.unit, equals('kg'));
      expect(measure.type, equals('any'));
      expect(measure.required, equals(false));
    });

    test('Measure.text factory should return a new instance with required true',
        () {
      final measure =
          Measure.text(name: 'test', value: '10', unit: 'kg', required: true);

      expect(measure.name, equals('test'));
      expect(measure.value, equals('10'));
      expect(measure.isNumber, equals(false));
      expect(measure.unit, equals('kg'));
      expect(measure.type, equals('any'));
      expect(measure.required, equals(true));
    });
  });
}
