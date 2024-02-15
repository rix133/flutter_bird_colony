import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kakrarahu/models/bird.dart';
import 'package:kakrarahu/models/experiment.dart';
import 'package:kakrarahu/models/experimented_item.dart';
import 'package:kakrarahu/models/firestore_item.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/models/updateResult.dart';
import 'package:kakrarahu/services/deleteService.dart';


class Nest implements FirestoreItem, ExperimentedItem {
  String? id;
  String accuracy;
  GeoPoint coordinates;
  String? remark;
  String? responsible;
  String? species;
  bool? completed;
  DateTime discover_date;
  DateTime last_modified;
  DateTime? first_egg;
  List<Experiment>? experiments = [];
  List<Object>? changelogs;
  List<Measure> measures = [];
  List<Bird>? parents = [];

  String get name => id ?? "New Nest";

  Nest({this.id,
    required this.discover_date,
    required this.last_modified,
    required this.accuracy,
    required this.coordinates,
    required this.responsible,
    required this.experiments,
    this.completed,
    this.first_egg,
    this.species,
    this.remark,
    this.parents,
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

  Marker getMarker(BuildContext context, bool visibility){
    return Marker(
        infoWindow: InfoWindow(
            title: id,
            onTap: () => Navigator.pushNamed(context, "/nestManage",
                arguments: {"sihtkoht": id})),
        consumeTapEvents: false,
        visible: visibility,
        markerId: MarkerId(id!),
        //visible: snapshot.data!.docs[i].get("last_modified").toDate().day==today,
        icon: BitmapDescriptor.defaultMarkerWithHue(getMarkerColor()),
        position: LatLng(coordinates.latitude, coordinates.longitude));
  }

  getMarkerColor() {
    if (completed != null) {
      if(completed!){
        return BitmapDescriptor.hueAzure;
      }
    }
    if(first_egg != null){
      if(DateTime.now().difference(first_egg!).inDays > 10){
        return BitmapDescriptor.hueMagenta;
      }
    }

    if (chekedAgo() > Duration(days: 3)) {
      return BitmapDescriptor.hueRed;
    }
    else if (!checkedToday()) {
      return BitmapDescriptor.hueYellow;
    }
    return BitmapDescriptor.hueGreen;
  }

  checkedToday() {
    return last_modified.toIso8601String().split("T")[0] ==
        DateTime.now().toIso8601String().split("T")[0];
  }


  @override
  factory Nest.fromDocSnapshot(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    Nest nnest = Nest(
        id: snapshot.id,
        //assign a last century date
        discover_date:
        (json['discover_date'] as Timestamp? ?? Timestamp(0, 0)).toDate(),
        last_modified:
        (json['last_modified'] as Timestamp? ?? Timestamp(0, 0)).toDate(),
        accuracy: json['accuracy'] as String? ?? '',
        remark: json["remark"],
        first_egg: json['first_egg'] != null
            ? (json['first_egg'] as Timestamp).toDate()
            : null,
        responsible: json["responsible"] as String? ?? '',
        coordinates: json['coordinates'] as GeoPoint? ?? GeoPoint(0, 0),
        completed: json['completed'] as bool? ?? false,
        parents: json['parents'] != null
            ? (json['parents'] as List<dynamic>)
            .map((e) => birdFromJson(e))
            .toList()
            : [],
        experiments: (json['experiments'] as List<dynamic>?)
            ?.map((e) => experimentFromSimpleJson(e))
            .toList() ??
            [],
        // provide a default value if 'experiments' does not exist
        measures: (json['measures'] as List<dynamic>?)
            ?.map((e) => measureFromJson(e))
            .toList() ??
            [],
        // provide a default value if 'measures' does not exist
        species: json['species'] as String? ?? '');
    if (nnest.remark != null) {
      if(nnest.remark!.isNotEmpty){
      nnest.measures?.add(Measure(
          name: "note",
          type: "nest",
          value: nnest.remark!,
          isNumber: false,
          unit: "",
          modified: nnest.last_modified));
    }}
    if(nnest.measures.where((element) => element.name == "note").isEmpty){
      nnest.measures.add(Measure(
          name: "note",
          type: "nest",
          value: "",
          isNumber: false,
          unit: "",
          modified: nnest.last_modified));
    }
    //add measures from experments to the nest
    nnest.experiments?.forEach((Experiment e) {
      e.measures?.forEach((Measure m) {
        //add the measure if it does not exist and its type is mest or any
        if (nnest.measures
            .where((element) => element.name == m.name)
            .isEmpty &&
            (m.type == "nest" || m.type == "any")) {
          nnest.measures.add(m);
        }
      });
    });
    nnest.measures.sort();
    return nnest;
  }

  Future<UpdateResult> _write2Firestore(CollectionReference nests) async {
    // the modified date is assigned at write time
    last_modified = DateTime.now();
    return (await nests
        .doc(name)
        .set(toJson())
        .whenComplete(() => nests
        .doc(name)
        .collection("changelog")
        .doc(last_modified.toString())
        .set(toJson()))
        .then((value) => UpdateResult.saveOK(item:this))
        .catchError((e) => UpdateResult.error(message: e.toString())));
  }

  @override
  Future<UpdateResult> save({CollectionReference<Object?>? otherItems = null,
    bool allowOverwrite = false,
    type = "default"}) async {
    if (name.isEmpty) {
      return UpdateResult.error(message: "Nest name can't be empty");
    }
    //remove empty measures
    measures.removeWhere((element) => element.value.isEmpty);

    CollectionReference nests =
    FirebaseFirestore.instance.collection(DateTime
        .now()
        .year
        .toString());
    if (type == "modify" || type == "default") {
      return _write2Firestore(nests);
      }

      throw UnimplementedError();
    }

  @override
  Future<UpdateResult> delete({CollectionReference<Object?>? otherItems = null,
    bool soft = true,
    type = "default"}) async {
    // delete from the bird as well if asked for
    if (otherItems != null) {
      parents?.forEach((Bird b) {
        otherItems
            .doc(b.band)
            .update({'nest': null, 'nest_year': null})
            .then((value) => true)
            .catchError((error) => false);
      });
    }
    CollectionReference items =
    FirebaseFirestore.instance.collection(DateTime.now().year.toString());
    if (!soft) {
      return await items
          .doc(id)
          .delete()
          .then((value) => UpdateResult.deleteOK(item: this))
          .catchError((error) => UpdateResult.error(message: error.toString()));
    } else {
      CollectionReference deletedCollection = FirebaseFirestore.instance
          .collection("deletedItems")
          .doc("Nests_" + DateTime.now().year.toString())
          .collection("deleted");

      //check if the item is already in deleted collection
      return deleteFiresoreItem(this, items, deletedCollection);
    }
  }

  toJson() {
    return {
      'discover_date': discover_date,
      'last_modified': DateTime.now(),
      'accuracy': accuracy,
      'first_egg': first_egg,
      'remark': remark,
      'responsible': responsible,
      'coordinates': coordinates,
      'completed': completed,
      'experiments': experiments?.map((e) => e.toSimpleJson()).toList(),
      'species': species,
      'parents': parents?.map((e) => e.toSimpleJson()).toList(),
      'measures': measures?.map((e) => e.toJson()).toList(),
    };
  }
  ListTile getListTile(BuildContext context){
    return ListTile(
      title: Text(name),
      subtitle: Text(checkedStr()),
      trailing: Icon(Icons.arrow_forward),
      onTap: () {
        //Navigator.pushNamed(context, '/nest', arguments: this);
      },
    );
  }

  bool isCompleted() {
    return completed ?? false;
  }

  Duration chekedAgo() {
    if (last_modified == null) {
      return Duration(days: -1);
    }
    return DateTime.now().difference(last_modified);
  }

  String checkedStr() {
    Duration difference = chekedAgo();
    if (difference.inDays > 0) {
      return "Checked ${difference.inDays} days ago";
    } else if (difference.inHours > 0) {
      return "CHECKED ${difference.inHours} hours ago";
    } else if (difference.inMinutes > 0) {
      return "CHECKED just now";
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
