import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/models/firestore/defaultSettings.dart';
import 'package:kakrarahu/models/firestore/species.dart';
import 'package:kakrarahu/models/markerColorGroup.dart';
import 'package:kakrarahu/models/measure.dart';

void main() {
  group('DefaultSettings', () {
    late FirebaseFirestore mockFirestore;

    setUp(() {
      mockFirestore = FakeFirebaseFirestore();
    });

    test('saves instance to firestore', () async {
      final settings = DefaultSettings(
        desiredAccuracy: 5.0,
        selectedYear: 2022,
        autoNextBand: true,
        autoNextBandParent: true,
        defaultLocation: GeoPoint(58.766218, 23.430432),
        biasedRepeatedMeasurements: true,
        measures: [],
        markerColorGroups: [],
        defaultSpecies: Species(english: 'Test', latinCode: 'T', local: 'Test'),
      );

      await settings.save(mockFirestore, type: 'custom');

      DefaultSettings savedSettings = await DefaultSettings.fromDocSnapshot(
          await mockFirestore.collection('settings').doc('custom').get());

      expect(savedSettings.desiredAccuracy, 5.0);
      expect(savedSettings.selectedYear, 2022);
      expect(savedSettings.autoNextBand, true);
      expect(savedSettings.autoNextBandParent, true);
      expect(savedSettings.defaultLocation, GeoPoint(58.766218, 23.430432));
      expect(savedSettings.biasedRepeatedMeasurements, true);
      expect(savedSettings.id, "custom");
      expect(savedSettings.measures, []);
      expect(savedSettings.defaultSpecies.english, 'Test');
      expect(savedSettings.markerColorGroups, []);
    });

    test('saves and reads instance to firestore with marker colors', () async {
      final settings = DefaultSettings(
        desiredAccuracy: 5.0,
        selectedYear: 2022,
        autoNextBand: true,
        autoNextBandParent: true,
        defaultLocation: GeoPoint(58.766218, 23.430432),
        biasedRepeatedMeasurements: true,
        measures: [],
        markerColorGroups: [MarkerColorGroup.magenta('Test')],
        defaultSpecies: Species(english: 'Test', latinCode: 'T', local: 'Test'),
      );

      await settings.save(mockFirestore, type: 'custom');

      DefaultSettings savedSettings = await DefaultSettings.fromDocSnapshot(
          await mockFirestore.collection('settings').doc('custom').get());

      expect(savedSettings.desiredAccuracy, 5.0);
      expect(savedSettings.selectedYear, 2022);
      expect(savedSettings.autoNextBand, true);
      expect(savedSettings.autoNextBandParent, true);
      expect(savedSettings.defaultLocation, GeoPoint(58.766218, 23.430432));
      expect(savedSettings.biasedRepeatedMeasurements, true);
      expect(savedSettings.id, "custom");
      expect(savedSettings.measures, []);
      expect(savedSettings.defaultSpecies.english, 'Test');
      expect(savedSettings.markerColorGroups.first.species, 'Test');
      expect(savedSettings.markerColorGroups.first.name, 'parent trapping');
    });

    test('copy should return a new instance with the same properties', () {
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

      final copy = settings.copy();

      expect(copy, isNot(same(settings)));
      expect(copy.desiredAccuracy, settings.desiredAccuracy);
      expect(copy.selectedYear, settings.selectedYear);
      expect(copy.autoNextBand, settings.autoNextBand);
      expect(copy.autoNextBandParent, settings.autoNextBandParent);
      expect(copy.defaultLocation, settings.defaultLocation);
      expect(
          copy.biasedRepeatedMeasurements, settings.biasedRepeatedMeasurements);
      expect(copy.defaultSpecies.english, settings.defaultSpecies.english);
      expect(copy.markerColorGroups, isEmpty);
    });

    test('copy should return a new instance with the same list items', () {
      final settings = DefaultSettings(
        desiredAccuracy: 5.0,
        selectedYear: 2022,
        autoNextBand: true,
        autoNextBandParent: true,
        defaultLocation: GeoPoint(58.766218, 23.430432),
        biasedRepeatedMeasurements: true,
        measures: [Measure.note()],
        defaultSpecies: Species(english: 'Test', latinCode: 'T', local: 'Test'),
        markerColorGroups: [MarkerColorGroup.magenta('Test')],
      );

      final copy = settings.copy();

      expect(copy.measures[0], isNot(same(settings.measures[0])));
      expect(copy.markerColorGroups[0],
          isNot(same(settings.markerColorGroups[0])));
    });

    test('deletes instance from firestore', () async {
      final settings = DefaultSettings(
        id: 'test',
        desiredAccuracy: 5.0,
        selectedYear: 2022,
        autoNextBand: true,
        autoNextBandParent: true,
        defaultLocation: GeoPoint(58.766218, 23.430432),
        biasedRepeatedMeasurements: true,
        measures: [],
        markerColorGroups: [],
        defaultSpecies: Species(english: 'Test', latinCode: 'T', local: 'Test'),
      );
      await settings.save(mockFirestore);
      await settings.delete(mockFirestore);

      var item = await mockFirestore.collection('settings').doc('test').get();
      expect(item.exists, false);
    });

    test('delete does nothing to no id instance', () async {
      final settings = DefaultSettings(
        id: null,
        desiredAccuracy: 5.0,
        selectedYear: 2022,
        autoNextBand: true,
        autoNextBandParent: true,
        defaultLocation: GeoPoint(58.766218, 23.430432),
        biasedRepeatedMeasurements: true,
        measures: [],
        markerColorGroups: [],
        defaultSpecies: Species(english: 'Test', latinCode: 'T', local: 'Test'),
      );
      var res = await settings.delete(mockFirestore);
      expect(res.success, true);
    });
  });
}
