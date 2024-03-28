import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter_bird_colony/models/firestore/defaultSettings.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultSettings', () {
    test('toExcelRowHeader should return correct headers', () {
      final settings = DefaultSettings(
        desiredAccuracy: 5.0,
        selectedYear: 2022,
        autoNextBand: true,
        autoNextBandParent: true,
        defaultLocation: GeoPoint(58.766218, 23.430432),
        biasedRepeatedMeasurements: true,
        measures: [],
        defaultSpecies: Species(english: 'Test', latinCode: 'T', local: 'Test'),
        markerColorGroups: [],
      );

      final headers = settings.toExcelRowHeader();
      expect(headers[0].value, 'Desired accuracy');
      expect(headers[1].value, 'Selected year');
      expect(headers[2].value, 'Auto next band');
      expect(headers[3].value, 'Auto next band parent');
      expect(headers[4].value, 'Default location');
      expect(headers[5].value, 'Biased repeated measurements');
      expect(headers[6].value, 'Default species');
      expect(headers[7].value, 'Responsible');
    });

    test('toExcelRows should return correct rows', () async {
      final settings = DefaultSettings(
        desiredAccuracy: 5.0,
        selectedYear: 2022,
        autoNextBand: true,
        autoNextBandParent: true,
        defaultLocation: GeoPoint(58.766218, 23.430432),
        biasedRepeatedMeasurements: true,
        measures: [],
        defaultSpecies: Species(english: 'Test', latinCode: 'T', local: 'Test'),
        markerColorGroups: [],
      );

      final rows = await settings.toExcelRows();
      expect((rows[0][0] as TextCellValue).value,
          settings.desiredAccuracy.toString());
      expect((rows[0][1] as TextCellValue).value,
          settings.selectedYear.toString());
      expect((rows[0][2] as TextCellValue).value,
          settings.autoNextBand.toString());
      expect((rows[0][3] as TextCellValue).value,
          settings.autoNextBandParent.toString());
      expect((rows[0][4] as TextCellValue).value,
          settings.defaultLocation.toString());
      expect((rows[0][5] as TextCellValue).value,
          settings.biasedRepeatedMeasurements.toString());
      expect((rows[0][6] as TextCellValue).value,
          settings.defaultSpecies.toString());
      expect((rows[0][7] as TextCellValue).value, settings.responsible ?? '');
    });
  });
}
