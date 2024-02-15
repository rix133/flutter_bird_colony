
class Species {
  const Species({
    required this.estonian,
    required this.english,
    required this.latinCode,
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
    return other is Species && other.english == english && other.estonian == estonian && other.latinCode==latinCode;
  }
  String bandLetters(){
    if(english == 'Common Gull'){
      return 'UA';
    }
    if(english == 'European Herring Gull'){
      return 'TA';
    }
    if(english == 'Lesser Black-backed Gull'){
      return 'L';
    }
    if(english == 'Great Black-backed Gull'){
      return 'L';
    }
    if(english == 'Common Tern'){
      return 'HK';
    }
    if(english == 'Arctic Tern'){
      return 'HK';
    }
    if(english == 'Great Cormorant'){
      return '';
    }
    if(english == 'Eurasian Oystercatcher'){
      return 'E';
    }
    if(english == 'Common Ringed Plover'){
      return 'PA';
    }
    if(english == 'Mute Swan'){
      return '';
    }
    if(english == 'Black-Headed Gull'){
      return '';
    }
    if(english == 'Greylag goose'){
      return '';
    }
    if(english == 'Mallard'){
      return '';
    }
    if(english == 'Little Gull'){
      return '';
    }
    return '';
  }


  @override
  int get hashCode => Object.hash(estonian, english, latinCode);
}
class SpeciesList{
  SpeciesList._();
    static List<Species> english = <Species>[
      Species(english:'Common Gull',estonian:'kalakajakas',latinCode:'larcan'),
      Species(english:'European Herring Gull',estonian:'hõbekajakas',latinCode:'lararg'),
      Species(english:'Lesser Black-backed Gull',estonian:'tõmmukajakas',latinCode:'larfus'),
      Species(english:'Great Black-backed Gull',estonian:'merikajakas',latinCode:'larmar'),
      Species(english:'Common Tern',estonian:'jõgitiir',latinCode:'stehir'),
      Species(english:'Arctic Tern',estonian:'randtiir',latinCode:'steaea'),
      Species(english:'Great Cormorant',estonian:'kormoran',latinCode:'phacar'),
      Species(english:'Eurasian Oystercatcher',estonian:'merisk',latinCode:'haeost'),
      Species(english:'Common Ringed Plover',estonian:'liivatüll',latinCode:'chahia'),
      Species(english:'Mute Swan',estonian:'kühmnokk-luik',latinCode:'cygolo'),
      Species(english:'Black-Headed Gull',estonian:'naerukajakas',latinCode:'larrid'),
      Species(english:'Greylag goose',estonian:'hallhani',latinCode:'ansans'),
      Species(english:'Mallard',estonian:'sinikael-part',latinCode:'anapla'),
      Species(english:'Little Gull',estonian:'väikekajakas',latinCode:'hydmin'),
    ];

}