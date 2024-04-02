import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/models/updateResult.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Species', () {
    test('Species creation from English name', () {
      var species = Species.fromEnglish('Common Gull');
      expect(species.english, 'Common Gull');
      expect(species.local, '');
      expect(species.latinCode, '');
    });

    test('Species equality', () {
      var species1 = Species.fromEnglish('Common Gull');
      var species2 = Species.fromEnglish('Common Gull');
      expect(species1 == species2, true);
    });

    test('Species inequality', () {
      var species1 = Species.fromEnglish('Common Gull');
      var species2 = Species.fromEnglish('European Herring Gull');
      expect(species1 == species2, false);
    });

    test('Species band letters', () {
      var species = Species.fromEnglish('Common Gull');
      expect(species.getBandLetters(), 'UA');
    });

    test('Species band letters for unknown species', () {
      var species = Species.fromEnglish('Unknown Species');
      expect(species.getBandLetters(), '');
    });

    test('Species toJson', () {
      var species = Species.fromEnglish('Common Gull');
      expect(species.toJson(), {
        'english': 'Common Gull',
        'local': '',
        'latin': null,
        'latinCode': '',
        'responsible': null,
        'letters': ''
      });
    });

    test('created_date should return last_modified or DateTime(1900) if null',
        () {
      var species = Species.fromEnglish('Common Gull');
      species.last_modified = DateTime(2022, 1, 1);
      expect(species.created_date, DateTime(2022, 1, 1));

      species.last_modified = null;
      expect(species.created_date, DateTime(1900));
    });

    test('delete should return UpdateResult.deleteOK if id is null', () async {
      var species = Species.fromEnglish('Common Gull');
      var firestore = FakeFirebaseFirestore();
      var result = await species.delete(firestore);
      expect(result, isInstanceOf<UpdateResult>());
      expect(result.success, true);
    });

    test('changeLog should return sorted list of Species', () async {
      var species = Species.fromEnglish('Common Gull');
      species.id = '1';
      var firestore = FakeFirebaseFirestore();
      await firestore
          .collection('settings')
          .doc('default')
          .collection('species')
          .doc('1')
          .collection('changeLog')
          .add(species.toJson());
      var changeLog = await species.changeLog(firestore);
      expect(changeLog, isInstanceOf<List<Species>>());
      // Add more assertions based on your expected changeLog data
    });

    test('getSp should return Species.empty if input is null', () {
      var list = LocalSpeciesList.example();
      var species = list.getSp(null);
      expect(species, isInstanceOf<Species>());
      expect(species.english, '');
      expect(species.local, '');
      expect(species.latinCode, '');
    });

    test('Species fromJson', () {
      var species = Species.fromJson({'english': 'Common Gull'});
      expect(species.english, 'Common Gull');
      expect(species.local, '');
      expect(species.latinCode, '');
    });
  });

  group('LocalSpeciesList', () {
    test('Creation from map', () {
      var json = {
        '1': {'english': 'Common Gull', 'local': 'Gull', 'latinCode': 'CG'},
        '2': {
          'english': 'European Herring Gull',
          'local': 'Gull',
          'latinCode': 'EHG'
        },
      };
      var list = LocalSpeciesList.fromMap(json);
      expect(list.species.length, 2);
      expect(list.species[0].english, 'Common Gull');
      expect(list.species[1].english, 'European Herring Gull');
    });

    test('creation from factory example ', () {
      var list = LocalSpeciesList.example();
      expect(list.species.length, 33);
      bool hasDuplicates = list.species.toSet().length != list.species.length;
      expect(hasDuplicates, false);

      //check for duplicate english names
      hasDuplicates = list.species.map((e) => e.english).toSet().length !=
          list.species.length;
      expect(hasDuplicates, false, reason: 'Duplicate english names found');

      //check for duplicate latin names
      hasDuplicates = list.species.map((e) => e.latin).toSet().length !=
          list.species.length;
      expect(hasDuplicates, false, reason: 'Duplicate latin names found');
    });

    test('name should return local name when it is not empty', () {
      final species = Species(
        english: 'Test English',
        local: 'Test Local',
        latin: 'Test Latin',
        latinCode: 'T',
        responsible: 'Test Responsible',
        letters: 'Test Letters',
      );

      expect(species.name, 'Test Local');
    });

    test('name should return english name when local name is empty', () {
      final species = Species(
        english: 'Test English',
        local: '',
        latin: 'Test Latin',
        latinCode: 'T',
        responsible: 'Test Responsible',
        letters: 'Test Letters',
      );

      expect(species.name, 'Test English');
    });

    test('copy should return a new instance with the same properties', () {
      final species = Species(
        english: 'Test English',
        local: 'Test Local',
        latin: 'Test Latin',
        latinCode: 'T',
        responsible: 'Test Responsible',
        letters: 'Test Letters',
      );

      final copy = species.copy();

      expect(copy, isNot(same(species)));
      expect(copy.english, species.english);
      expect(copy.local, species.local);
      expect(copy.latin, species.latin);
      expect(copy.latinCode, species.latinCode);
      expect(copy.responsible, species.responsible);
      expect(copy.letters, species.letters);
    });

    test('Get species by english name', () {
      var speciesList = [
        Species.fromEnglish('Common Gull'),
        Species.fromEnglish('European Herring Gull'),
      ];
      var list = LocalSpeciesList.fromSpeciesList(speciesList);
      var species = list.getSpecies('Common Gull');
      expect(species.english, 'Common Gull');
    });

    test('Get species by english name case insensitive', () {
      var speciesList = [
        Species.fromEnglish('Common Gull'),
        Species.fromEnglish('European Herring Gull'),
      ];
      var list = LocalSpeciesList.fromSpeciesList(speciesList);
      var species = list.getSpecies('common gull');
      expect(species.english, 'Common Gull');
    });

    test('Get species by english name not found', () {
      var speciesList = [
        Species.fromEnglish('Common Gull'),
        Species.fromEnglish('European Herring Gull'),
      ];
      var list = LocalSpeciesList.fromSpeciesList(speciesList);
      var species = list.getSpecies('Unknown Species');
      expect(species.english, 'Unknown Species');
    });

    test('Get species by species object', () {
      var speciesList = [
        Species.fromEnglish('Common Gull'),
        Species.fromEnglish('European Herring Gull'),
      ];
      var list = LocalSpeciesList.fromSpeciesList(speciesList);
      var species = list.getSp(Species.fromEnglish('Common Gull'));
      expect(species.english, 'Common Gull');
    });

    test('Get species by species object not found', () {
      var speciesList = [
        Species.fromEnglish('Common Gull'),
        Species.fromEnglish('European Herring Gull'),
      ];
      var list = LocalSpeciesList.fromSpeciesList(speciesList);
      var species = list.getSp(Species.fromEnglish('Unknown Species'));
      expect(species.english, '');
    });
  });
}
