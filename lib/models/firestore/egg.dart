import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/eggStatus.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/firestore/firestoreItem.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/firestoreItemMixin.dart';
import 'package:flutter_bird_colony/models/updateResult.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';

import '../experimentedItem.dart';
import '../markerColorGroup.dart';
import '../measure.dart';
import 'bird.dart';

class Egg extends ExperimentedItem implements FirestoreItem {
  String? id;
  DateTime discover_date;
  String? responsible;
  String? ring;
  EggStatus status;
  DateTime? last_modified;
  List<Object>? changelogs;

  Egg({this.id,
    required this.discover_date,
    required this.responsible,
    required this.status,
      this.last_modified,
      this.ring,
    List<Experiment>? experiments,
    required List<Measure> measures
  }) : super(experiments: experiments, measures: measures) {
    updateMeasuresFromExperiments("egg");
  }

  @override
  List<UpdateResult> validate(SharedPreferencesService? sps,
      {List<FirestoreItem> otherItems = const []}) {
    //if egg is broken or missing, no need to validate
    if (!status.canMeasure) {
      return [];
    }

    return super.validate(sps, otherItems: otherItems);
  }

  @override
  Future<List<Egg>> changeLog(FirebaseFirestore firestore) async {
    return (firestore
        .collection(discover_date.year.toString())
        .doc(getNest())
        .collection("egg")
        .doc(id)
        .collection("changelog")
        .get()
        .then((value) {
      List<Egg> eggList =
          value.docs.map((e) => Egg.fromDocSnapshot(e)).toList();
      eggList.sort((a, b) => b.last_modified!.compareTo(
          a.last_modified!)); // Sort by last_modified in descending order
      return eggList;
    }));
  }

  @override
  String get itemName => "egg " + (this.getNr() ?? "");

  String get name => id ?? "New Egg";
  @override
  DateTime get created_date => discover_date;

  bool get ringed => ring != null && ring != "";

  Egg copy() {
    return Egg(
        id: id,
        discover_date: discover_date,
        responsible: responsible,
        ring: ring,
        status: status,
        last_modified: last_modified,
        experiments: experiments,
        measures: measures.map((e) => e.copy()).toList());
  }

  double getEggMass() {
    final matchingMeasures =
        measures.where((element) => element.name.toLowerCase() == "weight");
    if (matchingMeasures.isEmpty) {
      return 0.0; // No measure found
    }
    return double.tryParse(matchingMeasures.first.value) ?? 0;
  }

  bool get hatched => status.hasHatched();

  @override
  factory Egg.fromDocSnapshot(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    ExperimentedItem eitem = ExperimentedItem.fromJson(json);
    Egg it = Egg(
        id: snapshot.id,
        discover_date: (json['discover_date'] as Timestamp).toDate(),
        responsible: json["responsible"],
        ring: json['ring'],
        last_modified: (json['last_modified'] as Timestamp? ?? Timestamp.fromMillisecondsSinceEpoch(0)).toDate(),
        status: EggStatus(json['status'] ?? "intact"),
        experiments: eitem.experiments,
        measures: eitem.measures
    );
    it.updateMeasuresFromExperiments("egg");
    return it;
  }

  @override
  Future <UpdateResult> save(FirebaseFirestore firestore, {CollectionReference<Object?>? otherItems = null, bool allowOverwrite = false, type = "default"}) async {
    String? nestId = getNest();
    if(nestId == null){
      return UpdateResult.error(message: "No nest found");
    } else{
      last_modified = DateTime.now();
      //remove empty measures
      measures.removeWhere((element) => element.value.isEmpty);

      CollectionReference<Object?> eggCollection =  firestore.collection(discover_date.year.toString()).doc(nestId).collection("egg");
      if(id == null){
        id = nestId + " egg " + (await eggCollection.get()).docs.length.toString();
        eggCollection.doc(id).set(toJson()).then((value) => FSItemMixin().saveChangeLog(this, eggCollection)).catchError((e) => UpdateResult.error(message: e.toString()));
      } else {
      return( eggCollection.doc(id).set(toJson()).then((value) => FSItemMixin().saveChangeLog(this, eggCollection)).catchError((e) => UpdateResult.error(message: e.toString())));
      }
    }
    return UpdateResult.error(message: "Unexpected input!");
  }

  @override
  Future<UpdateResult> delete(FirebaseFirestore firestore,
      {CollectionReference<Object?>? otherItems = null,
      type = "default"}) async {
    String? nestId = getNest();
    if(nestId == null){
      return UpdateResult.error(message: "No nest found");
    } else{
      CollectionReference<Object?> eggCollection =  firestore.collection(discover_date.year.toString()).doc(nestId).collection("egg");
      if(id != null){
        return eggCollection.doc(id).delete().then((value) => UpdateResult.deleteOK(item:this)).catchError((e) => UpdateResult.error(message: e.toString()));
      } else {
        return UpdateResult.deleteOK(item: this);
      }
    }
  }

  @override
  List<TextCellValue> toExcelRowHeader() {
    List<TextCellValue> baseItems = [
      TextCellValue('nest'),
      TextCellValue('egg_nr'),
      TextCellValue("type"),
      TextCellValue('discover_date'),
      TextCellValue('last_checked_by'),
      TextCellValue('last_checked'),
      TextCellValue('ring'),
      TextCellValue('status'),
      TextCellValue('experiments')
    ];
    Map<String, List<Measure>> measuresMap = getMeasuresMap();
    List<TextCellValue> measureItems = measuresMap.map((key, value) => MapEntry(key, value.first.toExcelRowHeader())).values.expand((e) => e).toList();

    return [...baseItems, ...measureItems];
  }

  @override
  Future<List<List<CellValue>>> toExcelRows(
      {List<FirestoreItem>? otherItems}) async {
    List<CellValue> baseItems = [
      TextCellValue(getNest() ?? ""),
      TextCellValue(getNr() ?? ""),
      TextCellValue(type() ?? ""),
      DateCellValue(year: discover_date.year, month: discover_date.month, day: discover_date.day),
      TextCellValue(responsible ?? ""),
      last_modified != null ? DateTimeCellValue.fromDateTime(last_modified!) : TextCellValue(""),
      TextCellValue(ring ?? ""),
      TextCellValue(status.toString()),
      TextCellValue(experiments?.map((e) => e.name).join(";\r") ?? ""), // Convert experiments to string
    ];
    List<List<CellValue>> rows = addMeasuresToRow(baseItems);
    return rows;
  }

  String? getNest(){
    return(id?.split(" ")[0] ?? null);
  }

  String? getNr(){
    return(id?.split(" ")[2] ?? null);
  }

  String statusText(){
    String txt = "Egg " +
        (getNr() ?? "?") +
        " $status";
    if(ring != null){
      txt += "/$ring";
    }
    int dayDiff = DateTime.now().difference(discover_date).inDays;
    if (dayDiff > 0 && (ring == null || ring == "")) {
      txt += " " + dayDiff.toString() + " days old";
    }

    return txt;
  }


  ElevatedButton getButton(BuildContext context, Nest? nest){
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: status.color()),
      child: Text(statusText()),
      onPressed: () {
        Navigator.pushNamed(context, "/editEgg", arguments: this);
      },
      onLongPress: () {
        Map<String, dynamic> args = ringed
            ? {
                "nest": nest,
                "bird": Bird.fromEgg(this),
              }
            : {
                "nest": nest,
                "egg": this,
              };
        Navigator.pushNamed(context, "/editBird", arguments: args);
      },
    );
  }

  bool knownOrder(){
    return id?.contains("egg") ?? false;

  }

  String? type(){
    List<String>? items = id?.split(" ");
    if (items != null && items.length > 2) {
      return items[1];
    }
    return null;
  }

  Padding getAgeRow() {
    int ageDays = DateTime.now().difference(discover_date).inDays;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
              child: Text('$ageDays days since discovery',
                  style: TextStyle(fontSize: 20, color: Colors.yellow))),
        ],
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'discover_date': discover_date,
      'responsible': responsible,
      'ring': ring,
      'last_modified': last_modified ?? DateTime.now(),
      'status': status.toString(),
      'experiments': experiments?.map((e) => e.toSimpleJson()).toList(),
      'measures': measures.map((e) => e.toJson()).toList(),
    };
  }

  @override
  Widget getListTile(BuildContext context, FirebaseFirestore firestore,
      {bool disabled = false, List<MarkerColorGroup> groups = const []}) {
    return ListTile(
      title: Text(name),
      subtitle: Text(statusText()),
      onTap: () {
        Navigator.pushNamed(context, '/editEgg', arguments: this);
      },
    );
  }
}