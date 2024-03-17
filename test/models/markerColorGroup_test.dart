import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kakrarahu/models/markerColorGroup.dart';

void main() {
  group('MarkerColorGroup', () {
    test('should create a new MarkerColorGroup with magenta color', () {
      final species = 'testSpecies';
      final markerColorGroup = MarkerColorGroup.magenta(species);

      expect(markerColorGroup.color, BitmapDescriptor.hueMagenta);
      expect(markerColorGroup.species, species);
      expect(markerColorGroup.name, 'parent trapping');
    });

    test('should convert MarkerColorGroup to JSON and back', () {
      final original = MarkerColorGroup.magenta('testSpecies');
      final json = original.toJson();
      final fromJson = MarkerColorGroup.fromJson(json);

      expect(fromJson.color, original.color);
      expect(fromJson.species, original.species);
      expect(fromJson.name, original.name);
    });

    test('should update color when setColor is called', () {
      final markerColorGroup = MarkerColorGroup.magenta('testSpecies');
      final newColor = Colors.red;

      markerColorGroup.setColor(newColor);

      expect(markerColorGroup.color, HSVColor.fromColor(newColor).hue);
    });

    test('should return correct color when getColor is called', () {
      final markerColorGroup = MarkerColorGroup.magenta('testSpecies');
      final expectedColor =
          HSVColor.fromAHSV(1, markerColorGroup.color, 1, 1).toColor();

      final color = markerColorGroup.getColor();

      expect(color, expectedColor);
    });
  });
}
