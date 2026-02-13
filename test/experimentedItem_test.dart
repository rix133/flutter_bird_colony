import 'package:flutter_bird_colony/models/eggStatus.dart';
import 'package:flutter_bird_colony/models/experimentedItem.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/models/firestore/egg.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Experiment buildExperimentWithTypedMeasures() {
    return Experiment(
      id: 'exp-1',
      name: 'Typed measures experiment',
      measures: [
        Measure.text(name: 'm_any', type: 'any'),
        Measure.text(name: 'm_parent', type: 'parent'),
        Measure.text(name: 'm_chick', type: 'chick'),
        Measure.text(name: 'm_egg', type: 'egg'),
        Measure.text(name: 'm_nest', type: 'nest'),
      ],
    );
  }

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
        'note': everyElement(isA<Measure>()
            .having((m) => m.value, 'value', isIn(['note1', 'note2']))),
        'aaa': everyElement(
            isA<Measure>().having((m) => m.value, 'value', isIn(['1', '']))),
        // Assuming 'aaa' measures don't have specific values to check
      });
    });
  });

  group('Experiment measure filtering', () {
    test('Bird parent gets parent + any measures from experiments', () {
      final experiment = buildExperimentWithTypedMeasures();
      final bird = Bird(
        band: "123",
        ringed_date: DateTime.now(),
        ringed_as_chick: false,
        measures: [],
        experiments: [experiment],
      );

      final names = bird.measures.map((m) => m.name).toList();
      expect(names, contains('m_any'));
      expect(names, contains('m_parent'));
      expect(names, contains('note'));
      expect(names, isNot(contains('m_chick')));
      expect(names, isNot(contains('m_egg')));
      expect(names, isNot(contains('m_nest')));
    });

    test('Bird chick gets chick + any measures from experiments', () {
      final experiment = buildExperimentWithTypedMeasures();
      final now = DateTime.now();
      final bird = Bird(
        band: "124",
        ringed_date: DateTime(now.year, 1, 1),
        ringed_as_chick: true,
        nest_year: now.year,
        measures: [],
        experiments: [experiment],
      );

      final names = bird.measures.map((m) => m.name).toList();
      expect(names, contains('m_any'));
      expect(names, contains('m_chick'));
      expect(names, contains('note'));
      expect(names, isNot(contains('m_parent')));
      expect(names, isNot(contains('m_egg')));
      expect(names, isNot(contains('m_nest')));
    });

    test('Egg gets egg + any measures from experiments', () {
      final experiment = buildExperimentWithTypedMeasures();
      final egg = Egg(
        discover_date: DateTime.now(),
        responsible: "tester",
        status: EggStatus("intact"),
        measures: [],
        experiments: [experiment],
      );

      final names = egg.measures.map((m) => m.name).toList();
      expect(names, contains('m_any'));
      expect(names, contains('m_egg'));
      expect(names, contains('note'));
      expect(names, isNot(contains('m_parent')));
      expect(names, isNot(contains('m_chick')));
      expect(names, isNot(contains('m_nest')));
    });
  });
}
