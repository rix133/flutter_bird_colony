import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../species.dart';

class SharedPreferencesService extends ChangeNotifier {
  SharedPreferencesService(this._sharedPreferences);

  final SharedPreferences _sharedPreferences;


  String get email => _sharedPreferences.getString('email') ?? '';

  set email(String value) {
    _sharedPreferences.setString('email', value);
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

  List<String> get recentBands => _sharedPreferences.getStringList('recentBands') ?? [];

  void recentBand(String speciesEng, String value) {
    String bandGroup = SpeciesList.english.firstWhere((species) => species.english == speciesEng).bandLetters();
    Map<String, String> recentBands = jsonDecode(_sharedPreferences.getString('recentBands') ?? '{}');

    // Update the band for the species
    recentBands[bandGroup] = value;

    // Save the updated map back to SharedPreferences
    _sharedPreferences.setString('recentBands', jsonEncode(recentBands));
    notifyListeners();
  }

  String getRecentBand(String speciesEng) {
    String bandGroup = SpeciesList.english.firstWhere((species) => species.english == speciesEng).bandLetters();
    Map<String, String> recentBands = jsonDecode(_sharedPreferences.getString('recentBands') ?? '{}');
    return recentBands[bandGroup] ?? '';
  }
}
