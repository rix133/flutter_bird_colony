
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/updateResult.dart';

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

  Future <UpdateResult> save({CollectionReference<Object?>? otherItems = null, bool allowOverwrite = false, String type = "default"});

  Future <UpdateResult> delete({CollectionReference<Object?>? otherItems = null, bool soft = true, String type = "default"});

  //get a row in an excel table
  Future<List<List<CellValue>>> toExcelRows();

  List<TextCellValue> toExcelRowHeader();

  Widget getListTile(BuildContext context);



}