import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerColorGroup {
  double color;
  int minAge;
  int maxAge;
  int parents;
  List<String> species;
  final String name;

  MarkerColorGroup(
      {required this.color,
      required this.minAge,
      required this.maxAge,
      required this.parents,
      required this.species,
      required this.name});

  MarkerColorGroup.magenta(species)
      : this(
            color: BitmapDescriptor.hueMagenta,
            minAge: 10,
            maxAge: 36,
            parents: 2,
            species: [species],
            name: "Parent trapping");

  MarkerColorGroup.fromJson(Map<String, dynamic> json)
      : color = json['color'],
        minAge = json['minAge'],
        maxAge = json['maxAge'],
        parents = json['parents'],
        species = json['species'],
        name = json['name'];

  Map<String, dynamic> toJson() => {
        'color': color,
        'minAge': minAge,
        'maxAge': maxAge,
        'parents': parents,
        'species': species,
        'name': name
      };
}
