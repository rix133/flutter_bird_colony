  import 'package:cloud_firestore/cloud_firestore.dart';

class Bird {
  String? id;
  String? nest;
  String? age;
  String band;
  String? responsible;
  String? species;
  Timestamp ringed_date;
  String? egg;
  List<Object>? changelogs;

  Bird({this.id,
    required this.ringed_date,
    required this.band,
    this.responsible,
    this.species,
    this.age,
    this.nest,
    this.egg,
    this.changelogs});

  bool timeSpan(String range){
    if(range == "All"){return(true);}
    if(range == "Today"){
      var today = DateTime.now().toIso8601String().split("T")[0];
      return this.ringed_date.toDate().toIso8601String().split("T")[0].toString() == today;
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
        ringed_date: json['ringed_date'],
        band: json["band"],
        responsible: json["responsible"],
        egg: json['egg'],
        species: json['species'],
        nest: json['nest'],
        age: json['age']
        ));
  }
}
