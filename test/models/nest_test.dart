import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bird_colony/models/eggStatus.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/models/firestore/egg.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/markerColorGroup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  final markerColorGroup = [MarkerColorGroup.magenta("Test")];
  FirebaseFirestore firestore = FakeFirebaseFirestore();
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
            expect(marker.icon.runtimeType.toString(), 'DefaultMarker');
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
            //expect(marker.icon.runtimeType, BitmapDescriptor);
            expect(marker.icon.runtimeType.toString(), 'DefaultMarker');
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
        discover_date: DateTime.now().subtract(Duration(days: 20)),
        last_modified: DateTime.now(),
        //enforce today
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

  group("basic getters", () {
    test('Nest name when id is not null', () {
      var nest = Nest(
        id: 'Nest1',
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'Responsible Person',
        measures: [],
      );
      expect(nest.name, 'Nest1');
    });

    test('Nest name when id is null', () {
      var nest = Nest(
        id: null,
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'Responsible Person',
        measures: [],
      );
      expect(nest.name, 'New Nest');
    });

    test('Nest created_date', () {
      var discoverDate = DateTime(2022, 1, 1);
      var nest = Nest(
        id: 'Nest1',
        discover_date: discoverDate,
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'Responsible Person',
        measures: [],
      );
      expect(nest.created_date, discoverDate);
    });
  });

  group("Get from Firestore object", () {
    test('Nest save with empty name', () async {
      var nest = Nest(
        id: null,
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'Responsible Person',
        measures: [],
      );
      nest.id = '';
      var result = await nest.save(firestore);
      expect(result.success, false);
      expect(result.message, 'Nest name can\'t be empty');
    });

    test('Nest save with non-empty name', () async {
      var nest = Nest(
        id: 'Nest1',
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'Responsible Person',
        measures: [],
      );
      var result = await nest.save(firestore);
      expect(result.success, true);
    });

    test('Nest delete with non-null id', () async {
      var nest = Nest(
        id: 'Nest1',
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'Responsible Person',
        measures: [],
      );
      var result = await nest.delete(firestore);
      expect(result.success, true);
    });

    test('Nest delete with null id', () async {
      var nest = Nest(
        id: null,
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'Responsible Person',
        measures: [],
      );
      var result = await nest.delete(firestore);
      expect(result.success, true);
    });
  });

  group('Nest eggCount and eggs', () {
    final egg1 = Egg(
      id: "123 egg 1",
      discover_date: DateTime.now(),
      last_modified: DateTime.now(),
      status: EggStatus('intact'),
      responsible: 'John Doe',
      measures: [],
    );

    final egg2 = Egg(
      id: "123 egg 2",
      discover_date: DateTime.now(),
      last_modified: DateTime.now(),
      status: EggStatus('predated'),
      responsible: 'John Doe',
      measures: [],
    );

    final nest = Nest(
      id: "123",
      discover_date: DateTime.now(),
      last_modified: DateTime.now(),
      accuracy: '12.33m',
      coordinates: GeoPoint(0, 0),
      responsible: 'John Doe',
      measures: [],
    );
    test('eggs should return empty list when no eggs', () async {
      expect(await nest.eggs(firestore), []);
    });

    test('eggCount should return correct number of eggs', () async {
      await egg1.save(firestore);
      await egg2.save(firestore);
      expect(await nest.eggCount(firestore), 2);
    });

    test('eggs should return correct list of eggs when id is not null',
        () async {
      await egg1.save(firestore);
      await egg2.save(firestore);
      List<Egg> eggs = await nest.eggs(firestore);
      expect(eggs.length, 2);
      expect(eggs[0].id, "123 egg 1");
      expect(eggs[1].id, "123 egg 2");
      expect(eggs[0].status.toString(), "intact");
      expect(eggs[1].status.toString(), "predated");
    });
    group('Nest delete with parents', () {
      Bird bird1 = Bird(
        band: "123",
        species: "Test",
        nest: "123",
        nest_year: 2022,
        ringed_date: DateTime.now().subtract(Duration(days: 1000)),
        ringed_as_chick: true,
        measures: [],
      );

      Bird bird2 = Bird(
        band: "456",
        species: "Test",
        nest_year: 2022,
        nest: "123",
        ringed_date: DateTime.now().subtract(Duration(days: 1000)),
        ringed_as_chick: true,
        measures: [],
      );

      Nest nest = Nest(
        id: "123",
        discover_date: DateTime.now(),
        last_modified: DateTime.now(),
        accuracy: 'high',
        coordinates: GeoPoint(0, 0),
        responsible: 'John Doe',
        measures: [],
        parents: [bird1, bird2],
      );

      setUp(() async {
        await nest.save(firestore, allowOverwrite: true);
        //we can't save birds if they exist without confirmation of overwrite
        await bird1.save(firestore, allowOverwrite: true);
        await bird2.save(firestore, allowOverwrite: true);
      });

      test('should update parent birds when otherItems is not null', () async {
        var result = await nest.delete(firestore,
            otherItems: firestore.collection("Birds"));
        expect(result.success, true);
        Bird bird1n = await firestore
            .collection("Birds")
            .doc(bird1.band)
            .get()
            .then((value) => Bird.fromDocSnapshot(value));
        Bird bird2n = await firestore
            .collection("Birds")
            .doc(bird2.band)
            .get()
            .then((value) => Bird.fromDocSnapshot(value));
        expect(bird1n.nest, null);
        expect(bird2n.nest, null);
      });

      test('should not update parent birds when otherItems is null', () async {
        bird1 = await firestore
            .collection("Birds")
            .doc(bird1.band)
            .get()
            .then((value) => Bird.fromDocSnapshot(value));
        var result = await nest.delete(firestore);
        expect(result.success, true);

        Bird bird1n = await firestore
            .collection("Birds")
            .doc(bird1.band)
            .get()
            .then((value) => Bird.fromDocSnapshot(value));
        Bird bird2n = await firestore
            .collection("Birds")
            .doc(bird2.band)
            .get()
            .then((value) => Bird.fromDocSnapshot(value));
        expect(bird1n.nest, "123");
        expect(bird2n.nest, "123");
      });
    });
  });
}
