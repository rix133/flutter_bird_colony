import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kakrarahu/models/experimentedItem.dart';
import 'package:kakrarahu/models/firestore/bird.dart';
import 'package:kakrarahu/models/firestore/egg.dart';
import 'package:kakrarahu/models/firestore/experiment.dart';
import 'package:kakrarahu/models/firestore/firestoreItem.dart';
import 'package:kakrarahu/models/firestoreItemMixin.dart';
import 'package:kakrarahu/models/markerColorGroup.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/models/updateResult.dart';

class Nest extends ExperimentedItem implements FirestoreItem {
  String? id;
  String accuracy;
  GeoPoint coordinates;
  String? remark;
  String? responsible;
  String? species;
  bool? completed;
  DateTime discover_date;
  DateTime? last_modified;
  DateTime? first_egg;
  List<Bird>? parents = [];

  String get name => id ?? "New Nest";

  @override
  DateTime get created_date => discover_date;

  Nest(
      {this.id,
      required this.discover_date,
      required this.last_modified,
      required this.accuracy,
      required this.coordinates,
      required this.responsible,
      this.completed,
      this.first_egg,
      this.species,
      this.remark,
      this.parents,
      List<Experiment>? experiments,
      required List<Measure> measures})
      : super(experiments: experiments, measures: measures) {
    updateMeasuresFromExperiments("nest");
  }

  bool timeSpan(String range) {
    if (range == "All") {
      return (true);
    }
    if (range == "Today") {
      var today = DateTime.now().toIso8601String().split("T")[0];
      return this.last_modified?.toIso8601String().split("T")[0].toString() ==
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

  Marker getMarker(BuildContext context, bool visibility,
      List<MarkerColorGroup> group) {
    //disable button if the nest is from another year
    bool disabled = DateTime.now().year != discover_date.year;
    return Marker(
        infoWindow: InfoWindow(
            title: id,
            onTap: disabled
                ? null
                : () => Navigator.pushNamed(context, '/editNest', arguments: {
                      "nest_id": id,
                      "year": discover_date.year.toString()
                    })),
        consumeTapEvents: false,
        visible: visibility,
        markerId: MarkerId(id!),
        //visible: snapshot.data!.docs[i].get("last_modified").toDate().day==today,
        icon: BitmapDescriptor.defaultMarkerWithHue(getMarkerColor(group)),
        position: LatLng(coordinates.latitude, coordinates.longitude));
  }

  getMarkerColor(List<MarkerColorGroup> groups) {
    if (completed != null) {
      if (completed!) {
        return BitmapDescriptor.hueAzure;
      }
    }
    if (checkedToday()) {
      return BitmapDescriptor.hueGreen;
    }
    if (first_egg != null && groups.length > 0) {
      int dayDiff = DateTime.now().difference(first_egg!).inDays;
      for (MarkerColorGroup group in groups) {
        if ((parents?.length ?? 0) < group.parents &&
          dayDiff > group.minAge &&
          dayDiff < group.maxAge &&
            group.species == species) {
          return group.color;
      }
      }
    }

    if (chekedAgo() > Duration(days: 3)) {
      return BitmapDescriptor.hueRed;
    } else if (!checkedToday()) {
      return BitmapDescriptor.hueYellow;
    }
    return BitmapDescriptor.hueOrange;
  }

  checkedToday() {
    return last_modified?.toIso8601String().split("T")[0] ==
        DateTime.now().toIso8601String().split("T")[0];
  }

  @override
  factory Nest.fromDocSnapshot(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    ExperimentedItem eitem = ExperimentedItem.fromJson(json);
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
              .map((e) => Bird.fromJson(e))
              .toList()
          : [],
      species: json['species'] as String? ?? '',
      experiments: eitem.experiments,
      measures: eitem.measures,
    );
    if (nnest.remark != null) {
      if (nnest.remark!.isNotEmpty) {
        nnest.measures.add(Measure(
            name: "note",
            type: "nest",
            value: nnest.remark!,
            isNumber: false,
            unit: "",
            modified: nnest.last_modified ?? DateTime.now()));
      }
    }
    //add measures from experments to the nest
    nnest.updateMeasuresFromExperiments("nest");
    return nnest;
  }

  Future<UpdateResult> _write2Firestore(CollectionReference nests) async {
    // the modified date is assigned at write time
    last_modified = DateTime.now();
    return (await nests
        .doc(name)
        .set(toJson())
        .whenComplete(() => FSItemMixin().saveChangeLog(this, nests))
        .then((value) => UpdateResult.saveOK(item: this))
        .catchError((e) => UpdateResult.error(message: e.toString())));
  }

  @override
  Future<UpdateResult> save(FirebaseFirestore firestore,
      {CollectionReference<Object?>? otherItems = null,
      bool allowOverwrite = false,
      type = "default"}) async {
    if (name.isEmpty) {
      return UpdateResult.error(message: "Nest name can't be empty");
    }
    //remove empty measures
    measures.removeWhere((element) => element.value.isEmpty);

    CollectionReference nests =
        firestore.collection(discover_date.year.toString());
    if (type == "modify" || type == "default") {
      return _write2Firestore(nests);
    }

    throw UnimplementedError();
  }

  @override
  Future<UpdateResult> delete(FirebaseFirestore firestore,
      {CollectionReference<Object?>? otherItems = null,
      bool soft = true,
      type = "default"}) async {
    // delete from the bird as well if asked for
    if (otherItems != null) {
      parents?.forEach((Bird b) async {
        await otherItems
            .doc(b.band)
            .update({'nest': null, 'nest_year': null})
            .then((value) => true)
            .catchError((error) => false);
      });
    }
    CollectionReference items =
        firestore.collection(discover_date.year.toString());
    if (!soft) {
      return await items
          .doc(id)
          .delete()
          .then((value) => UpdateResult.deleteOK(item: this))
          .catchError((error) => UpdateResult.error(message: error.toString()));
    } else {
      CollectionReference deletedCollection = firestore
          .collection("deletedItems")
          .doc("Nests_" + DateTime.now().year.toString())
          .collection("deleted");

      //check if the item is already in deleted collection
      return FSItemMixin().deleteFiresoreItem(this, items, deletedCollection);
    }
  }

  double getAccuracy() {
    //remove all letters
    String number = accuracy.endsWith('m')
        ? accuracy.substring(0, accuracy.length - 1)
        : accuracy;
    if (number.isEmpty) {
      return 9999.9;
    }
    return double.tryParse(number) ?? 9999.9;
  }

  Future<List<List<CellValue>>> toExcelRows() async {
    List<CellValue> baseItems = [
      TextCellValue(name),
      DoubleCellValue(getAccuracy()),
      DoubleCellValue(coordinates.latitude),
      DoubleCellValue(coordinates.longitude),
      TextCellValue(species ?? ""),
      DateCellValue(
          year: discover_date.year,
          month: discover_date.month,
          day: discover_date.day),
      TextCellValue(responsible ?? ""),
      last_modified != null
          ? DateTimeCellValue.fromDateTime(last_modified!)
          : TextCellValue(""),
      first_egg != null
          ? DateCellValue.fromDateTime(first_egg!)
          : TextCellValue(''),
      IntCellValue(
          DateTime.now().difference(first_egg ?? DateTime(2200)).inDays),
      TextCellValue(experiments?.map((e) => e.name).join(";\r") ?? ""),
      TextCellValue(parents?.map((p) => p.name).join(";\r") ?? "")
    ];

    List<List<CellValue>> rows = addMeasuresToRow(baseItems);
    return rows;
  }

  toExcelRowHeader() {
    List<TextCellValue> baseItems = [
      TextCellValue('name'),
      TextCellValue('accuracy'),
      TextCellValue('latitude'),
      TextCellValue('longitude'),
      TextCellValue('species'),
      TextCellValue('discover_date'),
      TextCellValue('last_modified_by'),
      TextCellValue('last_modified'),
      TextCellValue('first_egg_date'),
      TextCellValue("days_since_first_egg"),
      TextCellValue('experiments'),
      TextCellValue('parents')
    ];
    Map<String, List<Measure>> measuresMap = getMeasuresMap();
    List<TextCellValue> measureItems = measuresMap
        .map((key, value) => MapEntry(key, value.first.toExcelRowHeader()))
        .values
        .expand((e) => e)
        .toList();

    return [...baseItems, ...measureItems];
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
      'measures': measures.map((e) => e.toJson()).toList(),
    };
  }

  ListTile getListTile(BuildContext context,
      {bool disabled = false, List<MarkerColorGroup> groups = const []}) {
    return ListTile(
        title: Text('ID: $name, $species'),
        subtitle: Text(checkedStr()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: Icon(Icons.map, color: Colors.black87),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        groups.isNotEmpty
                            ? getMarkerColor(groups)
                            : Colors.grey)),
                onPressed: disabled
                    ? null
                    : () {
                        Navigator.pushNamed(context, '/mapNests', arguments: {
                          'nest_ids': [id.toString()],
                          "year": discover_date.year.toString()
                        });
                      }),
            SizedBox(width: 10),
            IconButton(
                icon: Icon(Icons.edit, color: Colors.black87),
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.grey)),
                onPressed: disabled
                    ? null
                    : () {
                        Navigator.pushNamed(context, '/editNest', arguments: {
                          "nest": this,
                          "year": discover_date.year.toString()
                        });
                      }),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Colors.black87,
                title: Text("Nest details"),
                content: Column(
                  children: [
                    Text("Accuracy: $accuracy"),
                    Text(
                        "Coordinates: ${coordinates.latitude}, ${coordinates.longitude}"),
                    Text("Species: $species"),
                    Text(
                        "Discover date: ${discover_date.toIso8601String().split("T")[0]}"),
                    Text("Responsible: $responsible"),
                    Text(
                        "Last modified: ${last_modified?.toIso8601String().split("T")[0]}"),
                    Text("Completed: ${completed ?? false}"),
                    Text(
                        "First egg: ${first_egg?.toIso8601String().split("T")[0] ?? ""}"),
                    Text("${checkedStr()}"),
                    Text(
                        "Experiments: ${experiments?.map((e) => e.name).join(", ") ?? ""}"),
                    Text(
                        "Parents: ${parents?.map((p) => p.name).join(", ") ?? ""}"),
                    Text("Measures: ${measures.map((e) => e.name).join(", ")}"),
                  ],
                ),
              );
            },
          );
        });
  }

  bool isCompleted() {
    return completed ?? false;
  }

  Duration chekedAgo() {
    return DateTime.now().difference(last_modified ?? DateTime.now());
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

  Future<int> eggCount(FirebaseFirestore firestore) async {
    List<Egg> eggs = await this.eggs(firestore);
    return eggs.where((egg) => egg.type() == 'egg').length;
  }

  Future<List<Egg>> eggs(FirebaseFirestore firestore) {
    if (id == null) {
      return Future.value([]);
    }
    String year = discover_date.year.toString();
    CollectionReference eggs =
        firestore.collection(year).doc(id).collection("egg");
    return eggs.get().then(
        (value) => value.docs.map((e) => Egg.fromDocSnapshot(e)).toList());
  }
}
