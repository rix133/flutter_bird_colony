import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/services/locationService.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';

class MockGeolocatorPlatform extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() {
    return Future.value(true);
  }

  @override
  Future<LocationPermission> checkPermission() {
    return Future.value(LocationPermission.denied);
  }

  @override
  Future<LocationPermission> requestPermission() {
    return Future.value(LocationPermission.denied);
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    return Stream<Position>.fromIterable([
      Position(
          latitude: 58.766218,
          longitude: 23.430432,
          accuracy: 10.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          timestamp: DateTime.now(),
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0),
    ]);
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    return Future.value(Position(
        latitude: 58.888888,
        longitude: 23.888888,
        accuracy: 5.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        timestamp: DateTime.now(),
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0));
  }
}

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  group('LocationService', () {
    late LocationService locationService;
    late GeolocatorPlatform geolocatorPlatform;

    setUp(() {
      geolocatorPlatform = MockGeolocatorPlatform();
      GeolocatorPlatform.instance = geolocatorPlatform;
      locationService = LocationService.instance;
    });

    test('getPositionStream returns a stream of positions', () {
      TestWidgetsFlutterBinding.ensureInitialized(); // Initialize the binding
      final stream = locationService.getPositionStream();
      expect(stream, isA<Stream<Position>>());
    });

    test('determinePosition returns true if location is OK', () async {
      TestWidgetsFlutterBinding.ensureInitialized(); // Initialize the binding
      final context = MockBuildContext();
      final locOK = true;

      final result = await locationService.determinePosition(context, locOK);
      expect(result, true);
    });
  });
}
