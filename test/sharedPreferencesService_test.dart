import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kakrarahu/models/firestore/defaultSettings.dart';
import 'package:kakrarahu/models/firestore/species.dart';
import 'package:kakrarahu/models/markerColorGroup.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks/mocSharedPreferences.dart';

void main() {
  group('SharedPreferencesService', () {
    late SharedPreferences sharedPreferences;
    late SharedPreferencesService sharedPreferencesService;

    setUp(() {
      sharedPreferences = MockSharedPreferences();
      sharedPreferencesService = SharedPreferencesService(sharedPreferences);
    });

    test('settingsType should return default if not set', () {
      expect(sharedPreferencesService.settingsType, 'default');
    });

    test('settingsType should return the set value', () {
      sharedPreferencesService.settingsType = 'custom';
      expect(sharedPreferencesService.settingsType, 'custom');
    });

    test('email should return empty string if not set', () {
      expect(sharedPreferencesService.userEmail, '');
    });

    test('email should return the set value', () {
      sharedPreferencesService.userEmail = 'test@example.com';
      expect(sharedPreferencesService.userEmail, 'test@example.com');
    });

    test('username should return the set value', () {
      sharedPreferencesService.userName = 'Test User';
      expect(sharedPreferencesService.userName, 'Test User');
    });

    test('desiredAccuracy should return 4 if not set', () {
      expect(sharedPreferencesService.desiredAccuracy, 4);
    });

    test('desiredAccuracy should return the set value', () {
      sharedPreferencesService.desiredAccuracy = 2.5;
      expect(sharedPreferencesService.desiredAccuracy, 2.5);
    });

    test('selectedYear should return current year if not set', () {
      expect(sharedPreferencesService.selectedYear, DateTime.now().year);
    });

    test('selectedYear should return the set value', () {
      sharedPreferencesService.selectedYear = 2023;
      expect(sharedPreferencesService.selectedYear, 2023);
    });

    test('isLoggedIn should return false if not set', () {
      expect(sharedPreferencesService.isLoggedIn, false);
    });

    test('isLoggedIn should return the set value', () {
      sharedPreferencesService.isLoggedIn = true;
      expect(sharedPreferencesService.isLoggedIn, true);
    });

    test('autoNextBand should return false if not set', () {
      expect(sharedPreferencesService.autoNextBand, false);
    });

    test('markerColorGroups should return empty list if not set', () {
      expect(sharedPreferencesService.markerColorGroups, []);
    });

    test('autoNextBand should return the set value', () {
      sharedPreferencesService.autoNextBand = true;
      expect(sharedPreferencesService.autoNextBand, true);
    });

    test('autoNextBandParent should return false if not set', () {
      expect(sharedPreferencesService.autoNextBandParent, false);
    });

    test('autoNextBandParent should return the set value', () {
      sharedPreferencesService.autoNextBandParent = true;
      expect(sharedPreferencesService.autoNextBandParent, true);
    });

    test('isAdmin should return false if not set', () {
      expect(sharedPreferencesService.isAdmin, false);
    });

    test('isAdmin should return the set value', () {
      sharedPreferencesService.isAdmin = true;
      expect(sharedPreferencesService.isAdmin, true);
    });

    test('defaultSpecies should return "Common Gull" if not set', () {
      expect(sharedPreferencesService.defaultSpecies, 'Common Gull');
    });

    test('defaultSpecies should return the set value', () {
      sharedPreferencesService.defaultSpecies = 'Eagle';
      expect(sharedPreferencesService.defaultSpecies, 'Eagle');
    });

    test('should set and get desiredAccuracy', () {
      sharedPreferencesService.desiredAccuracy = 5;
      expect(sharedPreferencesService.desiredAccuracy, 5);
    });

    test('defaultMeasures should return empty list if not set', () {
      expect(sharedPreferencesService.defaultMeasures, []);
    });

    test('defaultMeasures should return the set value', () {
      Measure measure = Measure(
          name: 'test',
          value: '',
          unit: 'test',
          type: 'nest',
          isNumber: false,
          modified: DateTime.now());
      sharedPreferencesService.defaultMeasures = [measure];
      expect(sharedPreferencesService.defaultMeasures.length, 1);
      expect(sharedPreferencesService.defaultMeasures[0].name, 'test');
    });

    test('should set and get recent band for species', () {
      sharedPreferencesService.speciesList =
          LocalSpeciesList.fromStringList(['Common Gull', 'Arctic Tern']);
      sharedPreferencesService.setRecentBand('Common Gull', '123');
      expect(sharedPreferencesService.getRecentMetalBand('Common Gull'), '123');
    });

    test('should set and get localspecieslist', () {
      sharedPreferencesService.speciesList =
          LocalSpeciesList.fromStringList(['Common Gull', 'Arctic Tern']);
      expect(sharedPreferencesService.speciesList.species.length, 2);
      expect(
          sharedPreferencesService.speciesList
              .getSpecies("Common Gull")
              .english,
          'Common Gull');
    });

    test('should get and set biasedRepeatedMeasures', () {
      expect(sharedPreferencesService.biasedRepeatedMeasures, false);
      sharedPreferencesService.biasedRepeatedMeasures = true;
      expect(sharedPreferencesService.biasedRepeatedMeasures, true);
    });

    test('should clear all metal bands', () {
      sharedPreferencesService.speciesList =
          LocalSpeciesList.fromStringList(['Common Gull', 'Arctic Tern']);
      sharedPreferencesService.setRecentBand('Common Gull', '123');
      sharedPreferencesService.setRecentBand('Arctic Tern', '456');
      sharedPreferencesService.clearAllMetalBands();
      expect(sharedPreferencesService.getRecentMetalBand('Common Gull'), 'UA');
      expect(sharedPreferencesService.getRecentMetalBand('Arctic Tern'), 'HK');
    });

    test('should get and set defaultLocation', () {
      CameraPosition cameraPosition =
          CameraPosition(target: LatLng(12, 11), bearing: 270, zoom: 10);
      expect(sharedPreferencesService.defaultLocation.zoom, 16.35);
      sharedPreferencesService.defaultLocation = cameraPosition;
      //expect(sharedPreferencesService.defaultLocation.zoom, 10);
      expect(sharedPreferencesService.defaultLocation.target.latitude, 12);
      expect(sharedPreferencesService.defaultLocation.target.longitude, 11);
    });

    test('should set from defaultSettings', () {
      DefaultSettings defaultSettings = DefaultSettings(
          id: 'default',
          desiredAccuracy: 2,
          selectedYear: 2022,
          autoNextBand: true,
          autoNextBandParent: true,
          defaultLocation: GeoPoint(11, 10),
          biasedRepeatedMeasurements: true,
          defaultSpecies: Species(english: 'test', local: '', latinCode: ''),
          markerColorGroups: [MarkerColorGroup.magenta('test')],
          measures: [Measure.note()]);

      sharedPreferencesService.setFromDefaultSettings(defaultSettings);
      expect(sharedPreferencesService.desiredAccuracy, 2);
      expect(sharedPreferencesService.selectedYear, 2022);
      expect(sharedPreferencesService.autoNextBand, true);
      expect(sharedPreferencesService.autoNextBandParent, true);
      expect(sharedPreferencesService.defaultLocation.target.latitude, 11);
      expect(sharedPreferencesService.defaultLocation.target.longitude, 10);
      expect(sharedPreferencesService.biasedRepeatedMeasures, true);
      expect(sharedPreferencesService.defaultSpecies, 'test');
      expect(sharedPreferencesService.defaultMeasures.length, 1);
      expect(sharedPreferencesService.defaultMeasures[0].name, 'note');
      expect(sharedPreferencesService.markerColorGroups.length, 1);
      expect(sharedPreferencesService.markerColorGroups[0].species, 'test');
    });
  });
}
