import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakrarahu/models/experiment.dart';
import 'package:kakrarahu/models/firestore_item.dart';
import 'package:kakrarahu/models/measure.dart';


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
  List<Experiment> experiments = [];
  List<Object>? changelogs;
  List<Measure> measures = [];

  String get name => id ?? "New Nest";

  Nest(
      {this.id,
      required this.discover_date,
      required this.last_modified,
      required this.accuracy,
      required this.coordinates,
      required this.responsible,
      required this.experiments,
      this.completed,
      this.species,
      this.remark,
      required this.measures,
      this.changelogs});

  bool timeSpan(String range) {
    if (range == "All") {
      return (true);
    }
    if (range == "Today") {
      var today = DateTime.now().toIso8601String().split("T")[0];
      return this.last_modified.toIso8601String().split("T")[0].toString() ==
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
    Nest nnest = Nest(
        id: snapshot.id,
        //assign a last century date
        discover_date:
            (json['discover_date'] as Timestamp? ?? Timestamp(0, 0)).toDate(),
        last_modified:
            (json['last_modified'] as Timestamp? ?? Timestamp(0, 0)).toDate(),
        accuracy: json['accuracy'] as String? ?? '',
        remark: json["remark"] as String? ?? '',
        responsible: json["responsible"] as String? ?? '',
        coordinates: json['coordinates'] as GeoPoint? ?? GeoPoint(0, 0),
        completed: json['completed'] as bool? ?? false,
        experiments: (json['experiments'] as List<dynamic>?)
                ?.map((e) => experimentFromJson(e))
                .toList() ??
            [], // provide a default value if 'experiments' does not exist
        measures: (json['measures'] as List<dynamic>?)
            ?.map((e) => measureFromJson(e))
            .toList() ??
            [], // provide a default value if 'measures' does not exist
        species: json['species'] as String? ?? '');
    if(nnest.remark != null){
      nnest.measures?.add(Measure(
          name: "note",
          value: nnest.remark!,
          isNumber: false,
          unit: "",
          modified: nnest.last_modified));
    }
    return nnest;
  }

  @override
  Future<bool> save(
      {CollectionReference<Object?>? otherItems = null,
      bool allowOverwrite = false,
      type = "default"}) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> delete(
      {CollectionReference<Object?>? otherItems = null,
      bool soft = true,
      type = "default"}) async {
    throw UnimplementedError();
  }

  toJson() {
    return {
      'discover_date': discover_date,
      'last_modified': DateTime.now(),
      'accuracy': accuracy,
      'remark': remark,
      'responsible': responsible,
      'coordinates': coordinates,
      'completed': completed,
      'experiments': experiments.map((e) => e.toSimpleJson()).toList(),
      'species': species,
      'measures': measures?.map((e) => e.toJson()).toList(),
    };
  }

  bool isCompleted() {
    return completed ?? false;
  }
  Duration chekedAgo(){
    if(last_modified == null){
      return Duration(days: -1);
    }
    return DateTime.now().difference(last_modified);
  }

  String checkedStr() {
    Duration difference = chekedAgo();
    if (difference.inDays > 0) {
      return "Checked ${difference.inDays} days ago";
    } else if (difference.inHours > 0) {
      return "Checked ${difference.inHours} hours ago";
    } else if (difference.inMinutes > 0) {
      return "Checked just now";
    }
    return "";
  }

  Future<int> eggCount() {
    if (id == null) {
      return Future.value(0);
    }
    String year = discover_date.year.toString();
    CollectionReference eggs =
        FirebaseFirestore.instance.collection(year).doc(id).collection("egg");
    return eggs.get().then((value) => value.docs.length).catchError((e) => 0);
  }
}
