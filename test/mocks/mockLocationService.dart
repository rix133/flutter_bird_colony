import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/services/locationService.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';

class MockLocationAccuracy10 extends Mock implements LocationService {

  @override
  Future<bool> determinePosition(BuildContext context, bool locOK) {
    return Future.value(true);
  }


  Stream<Position> getPositionStream(
    {LocationAccuracy desiredAccuracy = LocationAccuracy.best, int? distanceFilter, bool? forceAndroidLocationManager}) {
    return Stream<Position>.fromIterable([
        Position(latitude: 58.766218, longitude: 23.430432, accuracy: 10.0, altitude: 0.0, heading: 0.0, speed: 0.0, speedAccuracy: 0.0, timestamp: DateTime.now(), altitudeAccuracy: 0.0, headingAccuracy: 0.0),
    ]);
  }

  Future<Position> getCurrentPosition({LocationAccuracy desiredAccuracy = LocationAccuracy.best, bool forceAndroidLocationManager = false}) {
    return Future.value(Position(
        latitude: 58.888888,
        longitude: 23.888888,
        accuracy: 3.2,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        timestamp: DateTime.now(),
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0));
  }
}

class MockLocationAccuracy4 extends Mock implements LocationService {

  @override
  Future<bool> determinePosition(BuildContext context, bool locOK) {
    return Future.value(true);
  }


  Stream<Position> getPositionStream(
      {LocationAccuracy desiredAccuracy = LocationAccuracy.best, int? distanceFilter, bool? forceAndroidLocationManager}) {
    return Stream<Position>.fromIterable([
        Position(latitude: 58.766218, longitude: 23.430432, accuracy: 4.0, altitude: 0.0, heading: 0.0, speed: 0.0, speedAccuracy: 0.0, timestamp: DateTime.now(), altitudeAccuracy: 0.0, headingAccuracy: 0.0),
    ]);
  }

  Future<Position> getCurrentPosition({LocationAccuracy desiredAccuracy = LocationAccuracy.best, bool forceAndroidLocationManager = false}) {
    return Future.value(Position(latitude: 58.888888, longitude: 23.888888, accuracy: 2.0, altitude: 0.0, heading: 0.0, speed: 0.0, speedAccuracy: 0.0, timestamp: DateTime.now(), altitudeAccuracy: 0.0, headingAccuracy: 0.0));
  }
}