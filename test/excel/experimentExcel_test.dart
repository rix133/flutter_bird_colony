import 'package:excel/excel.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Experiment toExcelRows and toExcelRowHeader', () {
    test('toExcelRowHeader should return correct headers', () {
      final experiment = Experiment(
        name: "Test Experiment",
        description: "Test Description",
        responsible: "Test Responsible",
        year: 2022,
        type: "nest",
        nests: ["Nest1", "Nest2"],
        birds: ["Bird1", "Bird2"],
      );

      final headers = experiment.toExcelRowHeader();
      expect(headers[0].value, 'experiment_name');
      expect(headers[1].value, 'experiment_description');
      expect(headers[2].value, 'experiment_responsible');
      expect(headers[3].value, 'experiment_year');
      expect(headers[4].value, 'experiment_type');
      expect(headers[5].value, 'experiment_last_modified');
      expect(headers[6].value, 'experiment_created');
      expect(headers[7].value, 'nest');
      expect(headers[8].value, 'bird');
    });

    test(
        'toExcelRows should return correct rows for experiment with nests and birds',
        () async {
      final experiment = Experiment(
        name: "Test Experiment",
        description: "Test Description",
        responsible: "Test Responsible",
        year: 2022,
        type: "nest",
        nests: ["Nest1", "Nest2"],
        birds: ["Bird1", "Bird2"],
      );

      final rows = await experiment.toExcelRows();
      expect((rows[0][0] as TextCellValue).value, experiment.name);
      expect((rows[0][1] as TextCellValue).value, experiment.description ?? "");
      expect((rows[0][2] as TextCellValue).value, experiment.responsible ?? "");
      expect((rows[0][3] as IntCellValue).value, experiment.year ?? 1900);
      expect((rows[0][4] as TextCellValue).value, experiment.type);
    });

    test(
        'toExcelRows should return correct rows for experiment without nests and birds',
        () async {
      final experiment = Experiment(
        name: "Test Experiment",
        description: "Test Description",
        responsible: "Test Responsible",
        year: 2022,
        type: "nest",
      );

      final rows = await experiment.toExcelRows();
      expect((rows[0][0] as TextCellValue).value, experiment.name);
      expect((rows[0][1] as TextCellValue).value, experiment.description ?? "");
      expect((rows[0][2] as TextCellValue).value, experiment.responsible ?? "");
      expect((rows[0][3] as IntCellValue).value, experiment.year ?? 1900);
      expect((rows[0][4] as TextCellValue).value, experiment.type);
    });
  });
}
