import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String get userEmail => _sharedPreferences.getString('userEmail') ?? '';

  set userEmail(String value) {
    _sharedPreferences.setString('userEmail', value);
    notifyListeners();
  }

  String get recentBand => _sharedPreferences.getString('recentBand') ?? '';

  set recentBand(String value) {
    _sharedPreferences.setString('recentBand', value);
    notifyListeners();
  }
}
