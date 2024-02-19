
class Species {
  const Species({
    required this.local,
    required this.english,
    required this.latinCode,
  });

  final String local;
  final String english;
  final String latinCode;

  @override
  String toString() {
    return '$english, $local,$latinCode';
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is Species && other.english == english && other.local == local && other.latinCode==latinCode;
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
  int get hashCode => Object.hash(local, english, latinCode);
}
class SpeciesList{
  SpeciesList._();
    static List<Species> english = <Species>[
      Species(english:'Common Gull',local:'kalakajakas',latinCode:'larcan'),
      Species(english:'European Herring Gull',local:'hõbekajakas',latinCode:'lararg'),
      Species(english:'Lesser Black-backed Gull',local:'tõmmukajakas',latinCode:'larfus'),
      Species(english:'Great Black-backed Gull',local:'merikajakas',latinCode:'larmar'),
      Species(english:'Common Tern',local:'jõgitiir',latinCode:'stehir'),
      Species(english:'Arctic Tern',local:'randtiir',latinCode:'steaea'),
      Species(english:'Great Cormorant',local:'kormoran',latinCode:'phacar'),
      Species(english:'Eurasian Oystercatcher',local:'merisk',latinCode:'haeost'),
      Species(english:'Common Ringed Plover',local:'liivatüll',latinCode:'chahia'),
      Species(english:'Mute Swan',local:'kühmnokk-luik',latinCode:'cygolo'),
      Species(english:'Black-Headed Gull',local:'naerukajakas',latinCode:'larrid'),
      Species(english:'Greylag goose',local:'hallhani',latinCode:'ansans'),
      Species(english:'Mallard',local:'sinikael-part',latinCode:'anapla'),
      Species(english:'Little Gull',local:'väikekajakas',latinCode:'hydmin'),
    ];

}