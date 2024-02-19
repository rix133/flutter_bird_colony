import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/defaultSettings.dart';
import '../species.dart';

class SharedPreferencesService extends ChangeNotifier {
  SharedPreferencesService(this._sharedPreferences);

  final SharedPreferences _sharedPreferences;


  String get email => _sharedPreferences.getString('email') ?? '';

  set email(String value) {
    _sharedPreferences.setString('email', value);
    notifyListeners();
  }

  double get desiredAccuracy => _sharedPreferences.getDouble('desiredAccuracy') ?? 4;

  set desiredAccuracy(double value) {
    _sharedPreferences.setDouble('desiredAccuracy', value);
    notifyListeners();
  }

  int get selectedYear => _sharedPreferences.getInt('selectedYear') ?? DateTime.now().year;

  String get selectedYearString => selectedYear == 2022 ? 'Nest' : selectedYear.toString();

  set selectedYear(int value) {
    _sharedPreferences.setInt('selectedYear', value);
    notifyListeners();
  }

  bool get isLoggedIn => _sharedPreferences.getBool('isLoggedIn') ?? false;

  set isLoggedIn(bool value) {
    _sharedPreferences.setBool('isLoggedIn', value);
    notifyListeners();
  }

  String get userName => _sharedPreferences.getString('userName') ?? '';

  set userName(String value) {
    _sharedPreferences.setString('userName', value);
    notifyListeners();
  }

  bool get autoNextBand => _sharedPreferences.getBool('autoNextBand') ?? false;

  set autoNextBand(bool value) {
    _sharedPreferences.setBool('autoNextBand', value);
    notifyListeners();
  }

  bool get autoNextBandParent => _sharedPreferences.getBool('autoNextBandParent') ?? false;

  set autoNextBandParent(bool value) {
    _sharedPreferences.setBool('autoNextBandParent', value);
    notifyListeners();
  }

  String get userEmail => _sharedPreferences.getString('userEmail') ?? '';

  set userEmail(String value) {
    _sharedPreferences.setString('userEmail', value);
    notifyListeners();
  }


  void recentBand(String speciesEng, String value) {
    String bandGroup = SpeciesList.english.firstWhere((species) => species.english == speciesEng).bandLetters();

    // Save the band for the species to SharedPreferences
    _sharedPreferences.setString(bandGroup, value);
    notifyListeners();
  }

  String getRecentMetalBand(String speciesEng) {
    String bandGroup = SpeciesList.english.firstWhere((species) => species.english == speciesEng).bandLetters();

    // Retrieve the band for the species from SharedPreferences
    return _sharedPreferences.getString(bandGroup) ?? bandGroup;
  }

  bool get isAdmin => _sharedPreferences.getBool('isAdmin') ?? false;

  set isAdmin(bool value) {
    _sharedPreferences.setBool('isAdmin', value);
    notifyListeners();
  }

  String get defaultSpecies => _sharedPreferences.getString('defaultSpecies') ?? 'Common Gull';

  set defaultSpecies(String value) {
    _sharedPreferences.setString('defaultSpecies', value);
    notifyListeners();
  }

  bool get biasedRepeatedMeasures => _sharedPreferences.getBool('biasedRepeatedMeasures') ?? false;

  set biasedRepeatedMeasures(bool value) {
    _sharedPreferences.setBool('biasedRepeatedMeasures', value);
    notifyListeners();
  }

  void clearAll() {
    _sharedPreferences.clear();
    notifyListeners();
  }

  void clearAllMetalBands() {
    SpeciesList.english.forEach((species) {
      String bandGroup = species.bandLetters();
      _sharedPreferences.remove(bandGroup);
    });
    notifyListeners();
  }

  setFromDefaultSettings(DefaultSettings defaultSettings) {
    desiredAccuracy = defaultSettings.desiredAccuracy;
    selectedYear = defaultSettings.selectedYear;
    autoNextBand = defaultSettings.autoNextBand;
    autoNextBandParent = defaultSettings.autoNextBandParent;
    biasedRepeatedMeasures = defaultSettings.biasedRepeatedMeasurements;
    defaultSpecies = defaultSettings.defaultSpecies.english;
    notifyListeners();
  }
}
