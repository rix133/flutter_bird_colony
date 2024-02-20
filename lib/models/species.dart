
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:kakrarahu/models/firestoreItem.dart';
import 'package:kakrarahu/models/updateResult.dart';

class Species implements FirestoreItem{
  Species({
    this.id,
    required this.english,
    required this.local,
    this.latin,
    required this.latinCode,
    this.responsible,
  });
  String? id;
  String local; //name in local langauge
  String english;
  String latinCode;
  String? latin;

  factory Species.fromDocSnapshot(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return Species(
      id: snapshot.id,
      english: data['english'] ?? '',
      local: data['local'] ?? '',
      latin: data['latin'],
      latinCode: data['latinCode']  ?? '',
    );
  }

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

  @override
  String? responsible;

  @override
  Future<UpdateResult> delete({CollectionReference<Object?>? otherItems = null, bool soft = true, String type = "default"}) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  String get name => local.isEmpty ? english : local;

  @override
  Future<UpdateResult> save({CollectionReference<Object?>? otherItems = null, bool allowOverwrite = false, String type = "default"}) {
    // TODO: implement save
    throw UnimplementedError();
  }

  @override
  List<TextCellValue> toExcelRowHeader() {
    // TODO: implement toExcelRowHeader
    throw UnimplementedError();
  }

  @override
  Future<List<List<CellValue>>> toExcelRows() {
    // TODO: implement toExcelRows
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
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