import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakrarahu/models/egg.dart';
import 'package:kakrarahu/models/firestore_item.dart';

import 'bird.dart';

class Nest implements FirestoreItem {
  String? id;
  String accuracy;
  GeoPoint coordinates;
  String? remark;
  String? responsible;
  String? species;
  bool? completed;
  DateTime discover_date;
  DateTime last_modified;
  List<Egg>? eggs = [];
  List<Object>? changelogs;
  List<Bird> parents = [];

  String get name => id ?? "New Nest";

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
  factory Nest.fromQuerySnapshot(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    return (Nest(
        id: snapshot.id,
        //assign a last century date
        discover_date: (json['discover_date'] as Timestamp? ?? Timestamp(0,0)).toDate(),
        last_modified: (json['last_modified'] as Timestamp? ?? Timestamp(0,0)).toDate(),
        accuracy: json['accuracy'] as String? ?? '',
        remark: json["remark"] as String? ?? '',
        responsible: json["responsible"] as String? ?? '',
        coordinates: json['coordinates'] as GeoPoint? ?? GeoPoint(0, 0),
        completed: json['completed'] as bool? ?? false,
        parents: json['parents'] != null ? (json['parents'] as List).map((i) => Bird.fromQuerySnapshot(i)).toList() : [],
        species: json['species'] as String? ?? ''));
  }

  @override
  Future <bool> save(CollectionReference<Object?> items, bool allowOverwrite) {
    throw UnimplementedError();
  }


  toJson() {
    return {
      'discover_date': discover_date,
      'last_modified': last_modified,
      'accuracy': accuracy,
      'remark': remark,
      'responsible': responsible,
      'coordinates': coordinates,
      'completed': completed,
      'parents': parents.map((e) => e.toJson()).toList(),
      'species': species,
    };
  }

  bool isCompleted() {
    return completed ?? false;
  }

  int eggCount() {
    return this.eggs?.length ?? 0;
  }
}
