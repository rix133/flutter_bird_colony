import 'dart:ui';

class SpeciesList {
  const SpeciesList({
    required this.estonian,
    required this.english,
    required this.latinCode
  });

  final String estonian;
  final String english;
  final String latinCode;

  @override
  String toString() {
    return '$english, $estonian,$latinCode';
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SpeciesList && other.english == english && other.estonian == estonian && other.latinCode==latinCode;
  }

  @override
  int get hashCode => hashValues(estonian, english, latinCode);
}
class Species{
  Species._();
    static List<SpeciesList> english = <SpeciesList>[
      SpeciesList(english:'Common Gull',estonian:'kalakajakas',latinCode:'larcan'),
      SpeciesList(english:'European Herring Gull',estonian:'hõbekajakas',latinCode:'lararg'),
      SpeciesList(english:'Lesser Black-backed Gull',estonian:'tõmmukajakas',latinCode:'larfus'),
      SpeciesList(english:'Great Black-backed Gull',estonian:'merikajakas',latinCode:'larmar'),
      SpeciesList(english:'Common Tern',estonian:'jõgitiir',latinCode:'stehir'),
      SpeciesList(english:'Arctic Tern',estonian:'randtiir',latinCode:'steaea'),
      SpeciesList(english:'Great Cormorant',estonian:'kormoran',latinCode:'phacar'),
      SpeciesList(english:'Eurasian Oystercatcher',estonian:'merisk',latinCode:'haeost'),
      SpeciesList(english:'Common Ringed Plover',estonian:'liivatüll',latinCode:'chahia'),
      SpeciesList(english:'Mute Swan',estonian:'kühmnokk-luik',latinCode:'cygolo'),
      SpeciesList(english:'Black-Headed Gull',estonian:'naerukajakas',latinCode:'larrid'),
      SpeciesList(english:'Greylag goose',estonian:'hallhani',latinCode:'ansans'),
      SpeciesList(english:'Mallard',estonian:'sinikael-part',latinCode:'anapla'),
      SpeciesList(english:'Little Gull',estonian:'väikekajakas',latinCode:'hydmin'),
    ];
}