import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakrarahu/models/egg.dart';

import 'bird.dart';

class Nest {
  String? id;
  String accuracy;
  GeoPoint coordinates;
  String? remark;
  String responsible;
  String? species;
  bool? completed;
  Timestamp discover_date;
  Timestamp last_modified;
  List<Egg>? eggs = [];
  List<Object>? changelogs;
  List<Bird> parents = [];

  Nest({this.id,
    required this.discover_date,
    required this.last_modified,
    required this.accuracy,
    required this.coordinates,
    required this.responsible,
    required this.parents,
    this.completed,
    this.species,
    this.remark,
    this.eggs,
    this.changelogs});

  bool timeSpan(String range) {
    if (range == "All") {
      return (true);
    }
    if (range == "Today") {
      var today = DateTime.now().toIso8601String().split("T")[0];
      return this
          .last_modified
          .toDate()
          .toIso8601String()
          .split("T")[0]
          .toString() ==
          today;
    }
    return false;
  }

  bool people(String range, String me) {
    if (range == "Everybody") {
      return (true);
    }
    if (range == "Me") {
      return this.responsible == me;
    }
    return false;
  }

  @override
  factory Nest.fromQuerySnapshot(QueryDocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    return (Nest(
        id: snapshot.id,
        //assign a last century date
        discover_date: json['discover_date'] as Timestamp? ?? Timestamp.fromDate(DateTime(1900)),
        last_modified: json['last_modified'] as Timestamp? ?? Timestamp.fromDate(DateTime(1900)),
        accuracy: json['accuracy'] as String? ?? '',
        remark: json["remark"] as String? ?? '',
        responsible: json["responsible"] as String? ?? '',
        coordinates: json['coordinates'] as GeoPoint? ?? GeoPoint(0, 0),
        completed: json['completed'] as bool? ?? false,
        parents: json['parents'] != null ? (json['parents'] as List).map((i) => Bird.fromQuerySnapshot(i)).toList() : [],
        species: json['species'] as String? ?? ''));
  }

  bool isCompleted() {
    return completed ?? false;
  }

  int eggCount() {
    return this.eggs?.length ?? 0;
  }
}
