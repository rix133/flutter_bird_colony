  import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakrarahu/models/egg.dart';

class Nest {
  String? id;
  String accuracy;
  GeoPoint coordinates;
  String? remark;
  String responsible;
  String? species;
  Timestamp discover_date;
  Timestamp last_modified;
  List<Egg>? eggs;
  List<Object>? changelogs;

  Nest({this.id,
    required this.discover_date,
    required this.last_modified,
    required this.accuracy,
    required this.coordinates,
    required this.responsible,
    this.species,
    this.remark,
    this.eggs,
    this.changelogs});

  bool timeSpan(String range){
    if(range == "All"){return(true);}
    if(range == "Today"){
      var today = DateTime.now().toIso8601String().split("T")[0];
      return this.last_modified.toDate().toIso8601String().split("T")[0].toString() == today;
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
  factory Nest.fromQuerySnapshot(QueryDocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    return (Nest(
        id: snapshot.id,
        discover_date: json['discover_date'],
        last_modified: json['last_modified'],
        accuracy: json['accuracy'],
        remark: json["remark"],
        responsible: json["responsible"],
        coordinates: json['coordinates'],
        species: json['species']
        ));
  }
}
