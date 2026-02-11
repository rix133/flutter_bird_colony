import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_bird_colony/models/eggStatus.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/models/firestore/egg.dart';
import 'package:flutter_bird_colony/models/updateResult.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FirebaseFirestore firestore = FakeFirebaseFirestore();

  group('Bird instance methods', () {
    test('should load bird when egg is stored as a number', () async {
      final docRef = firestore.collection("Birds").doc("BandEggNumeric");
      await docRef.set({
        'ringed_date': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'ringed_as_chick': true,
        'band': 'BandEggNumeric',
        'egg': 1,
        'measures': [],
      });

      final bird = Bird.fromDocSnapshot(await docRef.get());
      expect(bird.egg, "1");
    });

    test('should get egg if it exists', () async {
      final bird = Bird(
        band: "AA1234",
        egg: "1",
        nest: "1",
        ringed_date: DateTime.now(),
        ringed_as_chick: true,
        measures: [],
      );
      final egg = Egg(
          id: "1 egg 1",
          discover_date: DateTime.now().subtract(Duration(days: 2)),
          responsible: "Admin",
          ring: "AA1234",
          last_modified: DateTime.now().subtract(Duration(days: 1)),
          status: EggStatus('hatched'),
          measures: []);
      await egg.save(firestore);
      final result = await bird.getEgg(firestore);
      expect(result != null, true);
      expect(result!.id, "1 egg 1");
    });

    test('should not get egg if not ringed as chick', () async {
      final bird = Bird(
        band: "AA1234",
        egg: "1",
        nest: "1",
        ringed_date: DateTime.now(),
        ringed_as_chick: false,
        measures: [],
      );
      final egg = Egg(
          id: "1 egg 1",
          discover_date: DateTime.now().subtract(Duration(days: 2)),
          responsible: "Admin",
          ring: "AA1234",
          last_modified: DateTime.now().subtract(Duration(days: 1)),
          status: EggStatus('hatched'),
          measures: []);
      await egg.save(firestore);
      final result = await bird.getEgg(firestore);
      expect(result == null, true);
    });

    test('should not get egg if no nest', () async {
      final bird = Bird(
        band: "AA1234",
        egg: "1",
        nest: "",
        ringed_date: DateTime.now(),
        ringed_as_chick: true,
        measures: [],
      );
      final egg = Egg(
          id: "1 egg 1",
          discover_date: DateTime.now().subtract(Duration(days: 2)),
          responsible: "Admin",
          ring: "AA1234",
          last_modified: DateTime.now().subtract(Duration(days: 1)),
          status: EggStatus('hatched'),
          measures: []);
      await egg.save(firestore);
      final result = await bird.getEgg(firestore);
      expect(result == null, true);
    });
  });

  group('Bird save method', () {
    test('should return error when band and name are empty', () async {
      final bird = Bird(
        band: "",
        ringed_date: DateTime.now(),
        ringed_as_chick: true,
        measures: [],
      );

      final result = await bird.save(firestore);
      expect(result.success, false);
      expect(
          result.message, "Can't save bird without metal band and color band");
    });

    test('should return error when band has only letters', () async {
      final bird = Bird(
        band: "AA",
        ringed_date: DateTime.now(),
        ringed_as_chick: true,
        measures: [],
      );

      final result = await bird.save(firestore);
      expect(result.success, false);
      expect(result.message, "Band must contain numbers");
    });

    test('should return error when band is empty and type is parent', () async {
      final bird = Bird(
        band: "",
        ringed_date: DateTime.now(),
        ringed_as_chick: true,
        measures: [],
        nest: "Nest1",
        color_band: "Color1",
      );

      final result = await bird.save(firestore, type: "parent");
      expect(result.success, false);
      expect(result.message, "Can't save bird without metal band");
    });

    test('should return error when type is unknown', () async {
      final bird = Bird(
        band: "Band0",
        ringed_date: DateTime.now(),
        ringed_as_chick: true,
        measures: [],
      );

      final result = await bird.save(firestore, type: "unknown");
      expect(result.success, false);
      expect(result.message, "Unknown type of bird: unknown");
    });

    test('should save bird when band is not empty and type is parent',
        () async {
      final bird = Bird(
        band: "Band1",
        ringed_date: DateTime.now(),
        ringed_as_chick: true,
        measures: [],
      );

      final result = await bird.save(firestore, type: "parent");
      expect(result.success, true);
    });

    test('should save bird when band is not empty and type is chick', () async {
      final bird = Bird(
        band: "Band2",
        ringed_date: DateTime.now(),
        ringed_as_chick: true,
        measures: [],
      );

      final result = await bird.save(firestore, type: "chick");
      expect(result.success, true);
    });
    test('should save chick bird nest when set', () async {
      final bird = Bird(
        band: "Band3",
        ringed_date: DateTime.now(),
        ringed_as_chick: true,
        measures: [],
        nest: "Nest1",
      );

      final result = await bird.save(firestore, type: "chick");
      expect(result.success, true);
      Bird resB = result.item as Bird;
      expect(resB.nest, "Nest1");
      Bird fb = await firestore
          .collection("Birds")
          .doc(bird.band)
          .get()
          .then((value) => Bird.fromDocSnapshot(value));
      expect(fb.nest, "Nest1");
      expect(fb.color_band, null);
      expect(fb.getType(), "chick");
      expect(fb.nest_year, DateTime.now().year);
    });

    test("should save parent bird with nest and color band", () async {
      final bird = Bird(
        band: "Band4",
        ringed_date: DateTime.now(),
        ringed_as_chick: false,
        measures: [],
        nest: "Nest2",
        color_band: "Color2",
      );

      final result = await bird.save(firestore, type: "parent");
      expect(result.success, true);
      Bird fb = await firestore
          .collection("Birds")
          .doc(bird.band)
          .get()
          .then((value) => Bird.fromDocSnapshot(value));
      expect(fb.nest, "Nest2");
      expect(fb.color_band, "Color2");
      expect(fb.getType(), "parent");
      expect(fb.nest_year, DateTime.now().year);
    });

    test("should not overwrite existing bird by default", () async {
      Bird bird = Bird(
        band: "Band5",
        ringed_date: DateTime.now(),
        ringed_as_chick: false,
        measures: [],
        nest: "Nest2",
        color_band: "Color2",
      );

      UpdateResult result = await bird.save(firestore, type: "parent");
      expect(result.success, true);

      bird.nest = "Nest4";

      result = await bird.save(firestore, type: "parent");
      expect(result.success, false);

      Bird fb = await firestore
          .collection("Birds")
          .doc(bird.band)
          .get()
          .then((value) => Bird.fromDocSnapshot(value));
      expect(fb.nest, "Nest2");
      expect(fb.color_band, "Color2");
      expect(fb.getType(), "parent");
      expect(fb.nest_year, DateTime.now().year);
    });
  });

  group('Bird timeSpan method', () {
    test('should return true when range is "All"', () {
      final bird = Bird(
        band: "AA",
        ringed_date: DateTime.now(),
        ringed_as_chick: true,
        measures: [],
      );

      final result = bird.timeSpan("All");
      expect(result, true);
    });

    test('should return true when range is "Today" and ringed_date is today',
        () {
      final bird = Bird(
        band: "AA",
        ringed_date: DateTime.now(),
        ringed_as_chick: true,
        measures: [],
      );

      final result = bird.timeSpan("Today");
      expect(result, true);
    });

    test(
        'should return true when range is "This year" and ringed_date is this year',
        () {
      final bird = Bird(
        band: "AA",
        ringed_date: DateTime.now(),
        ringed_as_chick: true,
        measures: [],
      );

      final result = bird.timeSpan("This year");
      expect(result, true);
    });

    test(
        'should return true when range is a year and ringed_date is the same year',
        () {
      final bird = Bird(
        band: "AA",
        ringed_date: DateTime(2022),
        ringed_as_chick: true,
        measures: [],
      );

      final result = bird.timeSpan("2022");
      expect(result, true);
    });

    test(
        'should return false when range is a year and ringed_date is not the same year',
        () {
      final bird = Bird(
        band: "AA",
        ringed_date: DateTime(2021),
        ringed_as_chick: true,
        measures: [],
      );

      final result = bird.timeSpan("2022");
      expect(result, false);
    });
  });

  test("should overwrite existing bird if requested", () async {
    Bird bird = Bird(
      band: "Band5",
      ringed_date: DateTime.now(),
      ringed_as_chick: false,
      measures: [],
      nest: "Nest3",
      color_band: "Color3",
    );

    UpdateResult result =
        await bird.save(firestore, type: "parent", allowOverwrite: true);
    expect(result.success, true);

    bird.nest = "Nest4";

    result = await bird.save(firestore, type: "parent", allowOverwrite: true);
    expect(result.success, true);

    Bird fb = await firestore
        .collection("Birds")
        .doc(bird.band)
        .get()
        .then((value) => Bird.fromDocSnapshot(value));
    expect(fb.nest, "Nest4");
    expect(fb.color_band, "Color3");
    expect(fb.getType(), "parent");
    expect(fb.nest_year, DateTime.now().year);
  });
}
