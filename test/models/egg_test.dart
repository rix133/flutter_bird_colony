import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_bird_colony/models/eggStatus.dart';
import 'package:flutter_bird_colony/models/firestore/egg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String defaultID = '1 egg 1';
  FirebaseFirestore firestore = FakeFirebaseFirestore();
  group('Egg', () {
    test('Egg creation with required parameters', () {
      var egg = Egg(
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('intact'),
        measures: [],
      );
      expect(egg.discover_date, isNotNull);
      expect(egg.responsible, 'Responsible Person');
      expect(egg.status.toString(), 'intact');
    });

    test('Egg ringed status when ring is not null', () {
      var egg = Egg(
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('intact'),
        ring: 'Ring',
        measures: [],
      );
      expect(egg.ringed, true);
    });

    test('Egg ringed status when ring is null', () {
      var egg = Egg(
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('intact'),
        measures: [],
      );
      expect(egg.ringed, false);
    });

    test('Egg toJson with required parameters', () {
      var egg = Egg(
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('intact'),
        measures: [],
      );
      var json = egg.toJson();
      expect(json['discover_date'], isNotNull);
      expect(json['responsible'], 'Responsible Person');
      expect(json['status'], 'intact');
    });

    test('Egg knownOrder when id contains "egg"', () {
      var egg = Egg(
        id: '1 egg 1',
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('intact'),
        measures: [],
      );
      expect(egg.knownOrder(), true);
    });

    test('Egg knownOrder when id does not contain "egg"', () {
      var egg = Egg(
        id: '1 1',
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('intact'),
        measures: [],
      );
      expect(egg.knownOrder(), false);
    });
  });

  group('Egg type', () {
    test('Egg type when id contains "egg"', () {
      var egg = Egg(
        id: '1 egg 1',
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('intact'),
        measures: [],
      );
      expect(egg.type(), 'egg');
    });

    test('Egg type when id does not contain "egg"', () {
      var egg = Egg(
        id: '1 1',
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('intact'),
        measures: [],
      );
      expect(egg.type(), null);
    });

    test('Egg type when id does contains "chick"', () {
      var egg = Egg(
        id: '1 chick 1',
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('intact'),
        measures: [],
      );
      expect(egg.type(), "chick");
    });
  });

  group('Egg getAgeRow', () {
    test('Egg getAgeRow', () {
      var egg = Egg(
        discover_date: DateTime.now().subtract(Duration(days: 5)),
        responsible: 'Responsible Person',
        status: EggStatus('intact'),
        measures: [],
      );
      var ageRow = egg.getAgeRow();
      expect(ageRow, isNotNull);
    });
  });

  group('Egg statusText', () {
    String pre = 'Egg 1 ';
    String post = " 0 days old";
    defaultID = '1 egg 1';
    test('Egg statusText when status is "intact"', () {
      post = " 5 days old";
      var egg = Egg(
        id: defaultID,
        discover_date: DateTime.now().subtract(Duration(days: 5)),
        responsible: 'Responsible Person',
        status: EggStatus('intact'),
        measures: [],
      );
      expect(egg.statusText(), pre + 'intact' + post);
    });

    test('Egg statusText when status is "predated"', () {
      var egg = Egg(
        id: defaultID,
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('predated'),
        measures: [],
      );
      expect(egg.statusText(), pre + 'predated');
    });

    test('Egg statusText when status is "drowned"', () {
      var egg = Egg(
        id: defaultID,
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('drowned'),
        measures: [],
      );
      expect(egg.statusText(), pre + 'drowned');
    });

    test('Egg statusText when status is "unknown"', () {
      var egg = Egg(
        id: defaultID,
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('unknown'),
        measures: [],
      );
      expect(egg.statusText(), pre + 'unknown');
    });

    test('Egg statusText when status is "hatched"', () {
      var egg = Egg(
        id: defaultID,
        discover_date: DateTime.now().subtract(Duration(days: 5)),
        responsible: 'Responsible Person',
        status: EggStatus('hatched'),
        ring: 'ring',
        measures: [],
      );
      expect(egg.statusText(), pre + 'hatched/ring');
    });

    test('itemName should return "egg " and the number', () {
      var egg = Egg(
          id: '1 egg 1',
          discover_date: DateTime.now(),
          responsible: 'test',
          status: EggStatus('intact'),
          measures: []);
      expect(egg.itemName, 'egg 1');
    });

    test('name should return id or "New Egg" if id is null', () {
      Egg egg = Egg(
          id: null,
          discover_date: DateTime.now(),
          responsible: 'test',
          status: EggStatus('intact'),
          measures: []);
      expect(egg.name, 'New Egg');
    });

    test('changeLog should return sorted list of Eggs', () async {
      var egg = Egg(
          id: '1 egg 1',
          discover_date: DateTime.now(),
          responsible: 'test',
          status: EggStatus('intact'),
          measures: []);
      var firestore = FakeFirebaseFirestore();
      egg.save(firestore);
      var changeLog = await egg.changeLog(firestore);
      expect(changeLog, isInstanceOf<List<Egg>>());
      // Add more assertions based on your expected changeLog data
    });
  });
  group("save", () {
    test('Egg save with no nest', () async {
      var egg = Egg(
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('intact'),
        measures: [],
      );
      egg.id = null;
      var result = await egg.save(firestore);
      expect(result.success, false);
      expect(result.message, 'No nest found');
    });

    test('Egg save with new egg', () async {
      var egg = Egg(
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('intact'),
        measures: [],
      );
      egg.id = '1 egg 1';
      var result = await egg.save(firestore);
      expect(result.success, true);
    });

    test('Egg save with existing egg', () async {
      var egg = Egg(
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('intact'),
        measures: [],
      );
      egg.id = '1 egg 1';
      var result = await egg.save(firestore);
      expect(result.success, true);
    });

    test('Egg delete with no nest', () async {
      var egg = Egg(
        discover_date: DateTime.now(),
        responsible: 'Responsible Person',
        status: EggStatus('intact'),
        measures: [],
      );
      egg.id = null;
      var result = await egg.delete(firestore);
      expect(result.success, false);
      expect(result.message, 'No nest found');
    });
  });
}
