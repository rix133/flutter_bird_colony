import 'package:flutter_bird_colony/models/experimentedItem.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Excel Output', () {
    late ExperimentedItem experimentedItem;
    final Measure m = Measure(
      name: 'aaa',
      value: '1',
      unit: '',
      type: 'any',
      isNumber: true,
      repeated: true,
      modified: DateTime.now(),
    );

    List<Measure> measures = [];

    setUp(() {
      experimentedItem = ExperimentedItem(measures: measures);
    });

    test('getMeasuresMap should return a map of measures with adjusted lengths',
        () {
      // Arrange
      var n1 = Measure.note(value: 'note1');
      var n2 = Measure.note(value: 'note2');
      experimentedItem.measures = [n1, n2, m];
      // Act
      final result = experimentedItem.getMeasuresMap();

      // Assert
      expect(result.length, 2);
      expect(result['note']!.length, 2);
      expect(result['aaa']!.length, 2);

    });

    test('getMeasuresMap should return a map of measures when equal lengths',
        () {
      // Arrange
      // Arrange
      var n1 = Measure.note(value: 'note1');
      var n2 = Measure.note(value: 'note2');
      var m2 = Measure.empty(m);
      experimentedItem.measures = [n1, n2, m, m2];
      // Act
      final result = experimentedItem.getMeasuresMap();

      // Assert
      expect(result, {
        'note': [
          n1,
          n2,
        ],
        'aaa': [m, m2],
      });
    });
  });
}
