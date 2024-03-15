import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kakrarahu/models/firestore/bird.dart';
import 'package:kakrarahu/models/firestore/nest.dart';
import 'package:kakrarahu/models/markerColorGroup.dart';

void main() {
  final markerColorGroup = [MarkerColorGroup.magenta("Test")];
  final Bird bird = Bird(
    band: "1234",
    species: "Test",
    ringed_date: DateTime.now().subtract(Duration(days: 1000)),
    ringed_as_chick: true,
    measures: [],
  );
  group('Nest getters', () {
    test('should return correct name', () {
      final nest = Nest(
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );

      expect(nest.name, 'New Nest');
    });

    test('should return correct created date', () {
      final discoverDate = DateTime(2022, 1, 1);
      final nest = Nest(
        discover_date: discoverDate,
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );

      expect(nest.created_date, discoverDate);
    });

    // Add more tests for other properties and methods of the Nest class

    test('should return true for timeSpan("All")', () {
      final nest = Nest(
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );

      expect(nest.timeSpan("All"), true);
    });

    test('should return true for timeSpan("Today") when last_modified is today',
        () {
      final today = DateTime.now().toIso8601String().split("T")[0];
      final nest = Nest(
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );

      expect(
          nest.timeSpan("Today"),
          nest.last_modified?.toIso8601String().split("T")[0].toString() ==
              today);
    });

    test(
        'should return false for timeSpan("Today") when last_modified is not today',
        () {
      final today = DateTime.now().toIso8601String().split("T")[0];
      final nest = Nest(
        discover_date: DateTime.now(),
        last_modified: DateTime(2022, 1, 1),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );

      expect(
          nest.timeSpan("Today"),
          nest.last_modified?.toIso8601String().split("T")[0].toString() ==
              today);
    });

    test('should return false for timeSpan("InvalidRange")', () {
      final nest = Nest(
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );

      expect(nest.timeSpan("InvalidRange"), false);
    });

    test('should return true for people("Everybody")', () {
      final nest = Nest(
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );

      expect(nest.people("Everybody", "John Doe"), true);
    });

    test('should return true for people("Me") when responsible is "John Doe"',
        () {
      final nest = Nest(
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );

      expect(nest.people("Me", "John Doe"), true);
    });

    test(
        'should return false for people("Me") when responsible is not "John Doe"',
        () {
      final nest = Nest(
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'Jane Smith',
        measures: [],
      );

      expect(nest.people("Me", "John Doe"), false);
    });

    test('should return false for people("InvalidRange", "John Doe")', () {
      final nest = Nest(
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );

      expect(nest.people("InvalidRange", "John Doe"), false);
    });
  });

  group('Nest getMarker', () {
    testWidgets('should return correct marker with visibility true',
        (WidgetTester tester) async {
      final nest = Nest(
        id: "123",
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final marker = nest.getMarker(context, true, markerColorGroup);

            expect(marker.infoWindow.title, nest.id);
            expect(marker.consumeTapEvents, false);
            expect(marker.visible, true);
            expect(marker.markerId, MarkerId(nest.id!));
            expect(marker.icon.runtimeType, BitmapDescriptor);
            expect(marker.position.latitude, nest.coordinates.latitude);
            expect(marker.position.longitude, nest.coordinates.longitude);
            return Placeholder();
          },
        ),
      );
    });

    testWidgets('should return correct marker with visibility false',
        (WidgetTester tester) async {
      final nest = Nest(
        id: "123",
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        species: "Test",
        measures: [],
      );
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final marker = nest.getMarker(context, false, markerColorGroup);

            expect(marker.infoWindow.title, nest.id);
            expect(marker.consumeTapEvents, false);
            expect(marker.visible, false);
            expect(marker.markerId, MarkerId(nest.id!));
            expect(marker.icon.runtimeType, BitmapDescriptor);
            expect(marker.position.latitude, nest.coordinates.latitude);
            expect(marker.position.longitude, nest.coordinates.longitude);
            return Placeholder();
          },
        ),
      );
    });
  });

  group('Nest getMarkerColor', () {
    test('should return hueAzure when completed is true', () {
      final nest = Nest(
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
        completed: true,
      );

      expect(nest.getMarkerColor(markerColorGroup), BitmapDescriptor.hueAzure);
    });

    test('should return hueGreen when checkedToday is true', () {
      final nest = Nest(
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );

      expect(nest.getMarkerColor(markerColorGroup), BitmapDescriptor.hueGreen);
    });

    test(
        'should return hueMagenta when dayDiff is between 10 and 35 and not checked today',
        () {
      final nest = Nest(
        discover_date: DateTime.now(),
        last_modified: DateTime.now().subtract(Duration(days: 1)),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
        species: "Test",
        first_egg: DateTime.now().subtract(Duration(days: 20)),
      );

      expect(
          nest.getMarkerColor(markerColorGroup), BitmapDescriptor.hueMagenta);
    });

    test(
        'should return hueGreen when dayDiff is between 10 and 35 and checked today',
        () {
      final nest = Nest(
        discover_date: DateTime.now(),
        last_modified: DateTime.now().subtract(Duration(hours: 1)),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
        species: "Test",
        first_egg: DateTime.now().subtract(Duration(days: 20)),
      );

      expect(nest.getMarkerColor(markerColorGroup), BitmapDescriptor.hueGreen);
    });

    test(
        'should return hueGreen when dayDiff is between 10 and 35 and has 2 parents',
        () {
      final nest = Nest(
        discover_date: DateTime.now().subtract(Duration(days: 20)),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
        species: "Test",
        parents: [bird, bird],
        first_egg: DateTime.now().subtract(Duration(days: 20)),
      );

      expect(nest.getMarkerColor(markerColorGroup), BitmapDescriptor.hueGreen);
    });

    test(
        'should return hueGreen when dayDiff is between 10 and 35 and is not catchable species',
        () {
      final nest = Nest(
        discover_date: DateTime.now().subtract(Duration(days: 20)),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
        species: "Test2",
        first_egg: DateTime.now().subtract(Duration(days: 20)),
      );

      expect(nest.getMarkerColor(markerColorGroup), BitmapDescriptor.hueGreen);
    });

    test(
        'should return hueRed when dayDiff is between 10 and 35 and has 2 parents',
        () {
      final nest = Nest(
        discover_date: DateTime.now().subtract(Duration(days: 20)),
        last_modified: DateTime.now().subtract(Duration(days: 10)),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
        species: "Test",
        parents: [bird, bird],
        first_egg: DateTime.now().subtract(Duration(days: 20)),
      );

      expect(nest.getMarkerColor(markerColorGroup), BitmapDescriptor.hueRed);
    });

    test(
        'should return hueRed when dayDiff is between 10 and 35 and is not catchable species',
        () {
      final nest = Nest(
        discover_date: DateTime.now().subtract(Duration(days: 20)),
        last_modified: DateTime.now().subtract(Duration(days: 10)),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
        species: "Test2",
        first_egg: DateTime.now().subtract(Duration(days: 20)),
      );

      expect(nest.getMarkerColor(markerColorGroup), BitmapDescriptor.hueRed);
    });

    test('should return hueRed when chekedAgo is more than 3 days', () {
      final nest = Nest(
        discover_date: DateTime.now().subtract(Duration(days: 4)),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
        last_modified: DateTime.now().subtract(Duration(days: 4)),
      );

      expect(nest.getMarkerColor(markerColorGroup), BitmapDescriptor.hueRed);
    });

    test('should return hueYellow when checkedToday is false', () {
      final nest = Nest(
        discover_date: DateTime.now().subtract(Duration(days: 20)),
        last_modified: DateTime.now().subtract(Duration(days: 2)),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );

      expect(nest.getMarkerColor(markerColorGroup), BitmapDescriptor.hueYellow);
    });
  });

  group('Nest checkedToday', () {
    test('should return true when last_modified is today', () {
      final nest = Nest(
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );

      expect(nest.checkedToday(), true);
    });

    test('should return false when last_modified is not today', () {
      final nest = Nest(
        discover_date: DateTime(2022, 1, 1),
        last_modified: DateTime(2022, 1, 1),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
      );

      expect(nest.checkedToday(), false);
    });
  });
  group("Get from Firestore object", () {});
}
