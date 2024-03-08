import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Fake implements SharedPreferences {
  String? s;
  bool? b;
  double? d;
  int? i;
  List<String>? l;

  @override
  String? getString(String key) {
    return (s);
  }

  @override
  Future<bool> setString(String key, String value) {
    s = value;
    return Future.value(true);
  }

  @override
  bool? getBool(String key) {
    return (b);
  }

  @override
  Future<bool> setBool(String key, bool value) {
    b = value;
    return Future.value(true);
  }

  @override
  double? getDouble(String key) {
    return (d);
  }

  @override
  Future<bool> setDouble(String key, double value) {
    d = value;
    return Future.value(true);
  }

  @override
  List<String>? getStringList(String key) {
    return (l);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) {
    l = value;
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
}
