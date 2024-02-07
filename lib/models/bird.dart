  import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakrarahu/models/measure.dart';

class Bird {
  String? id;
  String? nest;
  String? age;
  String band;
  String? color_band;
  String? responsible;
  String? species;
  DateTime ringed_date;
  String? egg;
  List<Measure> measures = [];
  List<Object>? changelogs;

  Bird({this.id,
    required this.ringed_date,
    required this.band,
    this.color_band,
    this.responsible,
    this.species,
    this.age,
    this.nest,
    this.egg,
    required this.measures,
    this.changelogs});



  bool timeSpan(String range){
    if(range == "All"){return(true);}
    if(range == "Today"){
      var today = DateTime.now().toIso8601String().split("T")[0];
      return this.ringed_date.toIso8601String().split("T")[0].toString() == today;
    }
    return false;
  }
  bool people(String range, String me){
    if(range == "Everybody"){return(true);}
    if(range == "Me"){
      return this.responsible == me;
    }
    return false;
  }

  @override
  factory Bird.fromQuerySnapshot(QueryDocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    return (Bird(
      id: snapshot.id,
      ringed_date: (json['ringed_date'] as Timestamp).toDate(),
      band: json["band"] ?? '',
      color_band: json["color_band"] ?? null,
      responsible: json["responsible"] ?? null,
      egg: json['egg'] ?? null,
      species: json['species'] ?? null,
      nest: json['nest'] ?? null,
      age: json['age'] ?? null,
      measures: (json['measures'] as List<dynamic>?)?.map((e) => measureFromJson(e)).toList() ?? [], // provide a default value if 'measures' does not exist
    ));
  }

  Map<String, dynamic> toJson() {
    return {
      'ringed_date': ringed_date,
      'band': band,
      'color_band': color_band,
      'responsible': responsible,
      'species': species,
      'nest': nest,
      'age': age,
      'egg': egg,
      'measures': measures.map((e) => e.toJson()).toList(),
      'changelogs': changelogs
    };
  }

  Future<bool> _write2Firestore(CollectionReference birds, CollectionReference nests,  bool isParent) async {
        await birds.doc(band).set(toJson())
            .whenComplete(() => birds
            .doc(band)
            .collection("changelog")
            .doc(DateTime.now().toString())
            .set(toJson()))
            .whenComplete(() => nests
            .doc(nest)
            .collection(isParent ? "parent": "egg")
            .doc(isParent ? band : "$nest egg $egg")
            .update(isParent ? {'ring': band, 'color_ring': color_band} : {'ring': band, 'status':'hatched'}));
        return true;

  }

  Future <bool> save2Firestore(CollectionReference birds, CollectionReference nests,  bool isParent, bool allowOverwrite) async {
    if(allowOverwrite){
      return await _write2Firestore(birds, nests, isParent);
    } else{
      return await birds.doc(band).get().then((value) {
        if (!value.exists) {
          return _write2Firestore(birds, nests, isParent);
        } else{
          return false;
        }
      });
    }

  }
}
