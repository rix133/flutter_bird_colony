
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/updateResult.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';

import '../markerColorGroup.dart';

abstract class FirestoreItem{

  //ListTile getListTile(void Function(String?) removeFun,
  //    void Function(void Function()) setState, BuildContext context);
  String? id;
  String? responsible;
  String get name;
  DateTime? last_modified;
  DateTime get created_date;
  Map<String, dynamic> toJson();

  factory FirestoreItem.fromDocSnapshot(DocumentSnapshot<Map<String, dynamic>> documentSnapshot){
    throw UnimplementedError('fromDocSnapshot() must be implemented in subclasses');
  }

  Future<List<FirestoreItem>> changeLog(FirebaseFirestore firestore);

  FirestoreItem copy();

  List<UpdateResult> validate(SharedPreferencesService? sps,
      {List<FirestoreItem> otherItems = const []});

  Future <UpdateResult> save(FirebaseFirestore firestore, {CollectionReference<Object?>? otherItems = null, bool allowOverwrite = false, String type = "default"});

  Future<UpdateResult> delete(FirebaseFirestore firestore,
      {CollectionReference<Object?>? otherItems = null,
      String type = "default"});

  //get a row in an excel table
  Future<List<List<CellValue>>> toExcelRows(
      {List<FirestoreItem>? otherItems = null});

  List<TextCellValue> toExcelRowHeader();

  Widget getListTile(BuildContext context, FirebaseFirestore firestore,
      {bool disabled = false, List<MarkerColorGroup> groups = const []});
}