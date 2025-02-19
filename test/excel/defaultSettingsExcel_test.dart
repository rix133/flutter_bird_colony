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
        defaultCameraBearing: 270,
        defaultCameraZoom: 16.35,
        biasedRepeatedMeasurements: true,
        measures: [],
        defaultSpecies: Species(english: 'Test', latinCode: 'T', local: 'Test'),
        markerColorGroups: [],
      );

      final headers = settings.toExcelRowHeader();
      expect(headers[0].value.text, 'Desired accuracy');
      expect(headers[1].value.text, 'Selected year');
      expect(headers[2].value.text, 'Auto next band');
      expect(headers[3].value.text, 'Auto next band parent');
      expect(headers[4].value.text, 'Default location');
      expect(headers[5].value.text, 'Biased repeated measurements');
      expect(headers[6].value.text, 'Default species');
      expect(headers[7].value.text, 'Responsible');
    });

    test('toExcelRows should return correct rows', () async {
      final settings = DefaultSettings(
        desiredAccuracy: 5.0,
        selectedYear: 2022,
        autoNextBand: true,
        autoNextBandParent: true,
        defaultCameraBearing: 270,
        defaultCameraZoom: 16.35,
        defaultLocation: GeoPoint(58.766218, 23.430432),
        biasedRepeatedMeasurements: true,
        measures: [],
        defaultSpecies: Species(english: 'Test', latinCode: 'T', local: 'Test'),
        markerColorGroups: [],
      );

      final rows = await settings.toExcelRows();
      expect((rows[0][0] as TextCellValue).value.text,
          settings.desiredAccuracy.toString());
      expect((rows[0][1] as TextCellValue).value.text,
          settings.selectedYear.toString());
      expect((rows[0][2] as TextCellValue).value.text,
          settings.autoNextBand.toString());
      expect((rows[0][3] as TextCellValue).value.text,
          settings.autoNextBandParent.toString());
      expect((rows[0][4] as TextCellValue).value.text,
          settings.defaultLocation.toString());
      expect((rows[0][5] as TextCellValue).value.text,
          settings.biasedRepeatedMeasurements.toString());
      expect((rows[0][6] as TextCellValue).value.text,
          settings.defaultSpecies.toString());
      expect(
          (rows[0][7] as TextCellValue).value.text, settings.responsible ?? '');
    });
  });
}
