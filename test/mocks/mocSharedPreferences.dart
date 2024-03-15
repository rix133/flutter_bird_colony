import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Fake implements SharedPreferences {
  List<Map<String, String>> s = [];
  int? i;
  List<String>? l;
  List<String>? l2;
  String? UA;
  String? HK;

  @override
  String? getString(String key) {
    for (int i = 0; i < s.length; i++) {
      if (s[i].containsKey(key)) {
        return s[i][key];
      }
    }
    return null;
  }

  @override
  Future<bool> setString(String key, String value) {
    //if s has key replace it, else add it
    bool found = false;
    for (int i = 0; i < s.length; i++) {
      if (s[i].containsKey(key)) {
        s[i][key] = value;
        found = true;
      }
    }
    if (!found) {
      s.add({key: value});
    }
    return Future.value(true);
  }

  @override
  bool? getBool(String key) {
    return bool.tryParse(getString(key) ?? '') ?? null;
  }

  @override
  Future<bool> setBool(String key, bool value) {
    setString(key, value.toString());
    return Future.value(true);
  }

  @override
  double? getDouble(String key) {
    return double.tryParse(getString(key) ?? '') ?? null;
  }

  @override
  Future<bool> setDouble(String key, double value) {
    setString(key, value.toString());
    return Future.value(true);
  }

  @override
  List<String>? getStringList(String key) {
    if (key == 'defaultMeasures') {
      return l2;
    } else {
      return l;
    }
  }

  @override
  Future<bool> setStringList(String key, List<String> value) {
    if (key == 'defaultMeasures') {
      l2 = value;
    } else {
      l = value;
    }
    return Future.value(true);
  }

  @override
  int? getInt(String key) {
    return (i);
  }

  @override
  Future<bool> setInt(String key, int value) {
    i = value;
    return Future.value(true);
  }

  @override
  Future<bool> remove(String key) {
    //find the key and remove it
    for (int i = 0; i < s.length; i++) {
      if (s[i].containsKey(key)) {
        s.removeAt(i);
      }
    }

    return Future.value(true);
  }
}
