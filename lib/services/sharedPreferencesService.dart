import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kakrarahu/models/firestore/defaultSettings.dart';
import 'package:kakrarahu/models/firestore/species.dart';
import 'package:kakrarahu/models/markerColorGroup.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService extends ChangeNotifier {
  SharedPreferencesService(this._sharedPreferences);

  final SharedPreferences _sharedPreferences;

  String get settingsType => _sharedPreferences.getString('settingsType') ?? 'default';

  List<MarkerColorGroup> get markerColorGroups =>
      _sharedPreferences.getStringList('markerColorGroups') != null
          ? _sharedPreferences
              .getStringList('markerColorGroups')!
              .map((e) => MarkerColorGroup.fromJson(jsonDecode(e)))
              .toList()
          : [];

  set markerColorGroups(List<MarkerColorGroup> value) {
    _sharedPreferences.setStringList(
        'markerColorGroups', value.map((e) => jsonEncode(e.toJson())).toList());
    notifyListeners();
  }

  set settingsType(String value) {
    _sharedPreferences.setString('settingsType', value);
    notifyListeners();
  }


  double get desiredAccuracy => _sharedPreferences.getDouble('desiredAccuracy') ?? 4;

  set desiredAccuracy(double value) {
    _sharedPreferences.setDouble('desiredAccuracy', value);
    notifyListeners();
  }

  int get selectedYear => _sharedPreferences.getInt('selectedYear') ?? DateTime.now().year;

  // this is a workaround for legacy DB
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

  List<Measure> get defaultMeasures {
    List<String> measureJsonList = _sharedPreferences.getStringList('defaultMeasures') ?? [];
    return measureJsonList.map((e) => Measure.fromFormJson(jsonDecode(e))).toList();
  }

  set defaultMeasures(List<Measure> value) {
    List<String> measureJsonList = value.map((e) => jsonEncode(e.toFormJson())).toList();
    _sharedPreferences.setStringList('defaultMeasures', measureJsonList);
    notifyListeners();
  }


  void setRecentBand(String speciesEng, String value) {

    String bandGroup = speciesList.species.firstWhere((species) => species.english == speciesEng).getBandLetters();
    //print('Setting recent band for $speciesEng to $value');
    //print('Band group is $bandGroup');
    // Save the band for the species to SharedPreferences
    _sharedPreferences.setString(bandGroup, value);
    notifyListeners();
  }

  String getRecentMetalBand(String speciesEng) {
    String bandGroup = speciesList.species.firstWhere((species) => species.english == speciesEng).getBandLetters();

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

  LocalSpeciesList get speciesList {
    return LocalSpeciesList.fromSpeciesList(
   _sharedPreferences.getStringList('defaultSpeciesList')?.map((e) => Species.fromJson(jsonDecode(e))).toList() ??
            []);
  }


  set speciesList(LocalSpeciesList value) {
    List<String> speciesJsonList = value.species.map((e) => jsonEncode(e.toJson())).toList();
    _sharedPreferences.setStringList('defaultSpeciesList', speciesJsonList);
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
    speciesList.species.forEach((species) {
      String bandGroup = species.getBandLetters();
      _sharedPreferences.remove(bandGroup);
    });
    notifyListeners();
  }

  CameraPosition get defaultLocation {
    double lat = _sharedPreferences.getDouble('defaultLocationLat') ?? 0;
    double long = _sharedPreferences.getDouble('defaultLocationLong') ?? 0;
    return CameraPosition(target: LatLng(lat, long),  bearing: 270,
      zoom: 16.35);
  }

  set defaultLocation(CameraPosition value) {
    _sharedPreferences.setDouble('defaultLocationLat', value.target.latitude);
    _sharedPreferences.setDouble('defaultLocationLong', value.target.longitude);
    notifyListeners();
  }

  setFromDefaultSettings(DefaultSettings defaultSettings) {
    desiredAccuracy = defaultSettings.desiredAccuracy;
    selectedYear = defaultSettings.selectedYear;
    autoNextBand = defaultSettings.autoNextBand;
    autoNextBandParent = defaultSettings.autoNextBandParent;
    biasedRepeatedMeasures = defaultSettings.biasedRepeatedMeasurements;
    defaultSpecies = defaultSettings.defaultSpecies.english;
    defaultLocation = defaultSettings.getCameraPosition();
    defaultMeasures = defaultSettings.measures;
    markerColorGroups = defaultSettings.markerColorGroups;
    notifyListeners();
  }
}
