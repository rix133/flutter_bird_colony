import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/experiment.dart';
import 'package:kakrarahu/models/firestoreItem.dart';
import 'package:kakrarahu/models/firestoreItemMixin.dart';
import 'package:kakrarahu/models/nest.dart';
import 'package:kakrarahu/models/updateResult.dart';

import 'experimentedItem.dart';
import 'measure.dart';

class Egg extends ExperimentedItem implements FirestoreItem {
  String? id;
  DateTime discover_date;
  String? responsible;
  String? ring;
  String status;
  DateTime? last_modified;
  List<Object>? changelogs;

  Egg({this.id,
    required this.discover_date,
    required this.responsible,
    required this.status,
    required last_modified,
    this.ring,
    List<Experiment>? experiments,
    required List<Measure> measures
  }) : super(experiments: experiments, measures: measures) {
    updateMeasuresFromExperiments("egg");
  }

  String get name => id ?? "New Egg";
  @override
  DateTime get created_date => discover_date;

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
        status: json['status'],
        experiments: eitem.experiments,
        measures: eitem.measures
    );
    it.updateMeasuresFromExperiments("egg");
    return it;
  }

  @override
  Future <UpdateResult> save({CollectionReference<Object?>? otherItems = null, bool allowOverwrite = false, type = "default"}) async {
    String? nestId = getNest();
    if(nestId == null){
      return UpdateResult.error(message: "No nest found");
    } else{
      last_modified = DateTime.now();
      CollectionReference<Object?> eggCollection =  FirebaseFirestore.instance.collection(discover_date.year.toString()).doc(nestId).collection("egg");
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
  Future <UpdateResult> delete({CollectionReference<Object?>? otherItems = null, bool soft = true, type = "default"}) async {
    String? nestId = getNest();
    if(nestId == null){
      return UpdateResult.error(message: "No nest found");
    } else{
      CollectionReference<Object?> eggCollection =  FirebaseFirestore.instance.collection(discover_date.year.toString()).doc(nestId).collection("egg");
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
      TextCellValue('nr'),
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
  Future<List<List<CellValue>>> toExcelRows() async {
    List<CellValue> baseItems = [
      TextCellValue(getNest() ?? ""),
      TextCellValue(getNr() ?? ""),
      TextCellValue(type() ?? ""),
      DateCellValue(year: discover_date.year, month: discover_date.month, day: discover_date.day),
      TextCellValue(responsible ?? ""),
      last_modified != null  ? DateTimeCellValue(year: last_modified!.year, month: last_modified!.month, day: last_modified!.day, hour: last_modified!.hour, minute: last_modified!.minute, second: last_modified!.second) : TextCellValue(""),
      TextCellValue(ring ?? ""),
      TextCellValue(status),
      TextCellValue(experiments?.map((e) => e.name).join(", ") ?? ""), // Convert experiments to string
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
    if(DateTime.now().isAfter(discover_date)){
      txt += " " + DateTime.now().difference(discover_date).inDays.toString() + " days old";
    }

    return txt;
  }

  List<Widget> getEggForm(Function(Measure) addMeasure, bool hideValue){
    return [
      //statusField(_focusNode),
      ...measures.map((e) => e.getMeasureForm(addMeasure, hideValue)).toList(),
    ];

  }


  ElevatedButton getButton(BuildContext context, Nest? nest){
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: status == "intact" ||
              status == "unknown"
              ? Colors.green
              : (status == "broken" ||
              status == "missing" ||
              status == "predated" ||
              status == "drowned"
              ? Colors.red
              : Colors.orange[800])),
      child: Text(statusText()),
      onPressed: () {
        Navigator.pushNamed(context, "/editEgg", arguments: this);
      },
      onLongPress: () {
        Navigator.pushNamed(
            context, "/editParent",
            arguments: {
              "nest": nest,
              "egg": this,
            });
      },
    );
  }

  bool knownOrder(){
    return id?.contains("egg") ?? false;

  }

  String? type(){
    return(id?.split(" ")[1] ?? null);
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
      'last_modified': last_modified,
      'status': status,
      'experiments': experiments?.map((e) => e.toSimpleJson()).toList(),
      'measures': measures.map((e) => e.toJson()).toList(),
    };
  }
}