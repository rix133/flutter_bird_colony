import 'package:flutter_test/flutter_test.dart';
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

// Add more tests for other methods and properties of SharedPreferencesService

    // Add more tests for other methods and properties of SharedPreferencesService
  });
}
