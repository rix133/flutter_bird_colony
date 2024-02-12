//import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakrarahu/models/experiment.dart';

abstract class FirestoreItem{

  //ListTile getListTile(void Function(String?) removeFun,
  //    void Function(void Function()) setState, BuildContext context);
  Map<String, dynamic> toJson();

  Future <bool> save({CollectionReference<Object?>? otherItems = null, bool allowOverwrite = false, String type = "default"});

  Future <bool> delete({CollectionReference<Object?>? otherItems = null, bool soft = true, String type = "default"});


  String? id;
  String? responsible;
  List<Experiment> experiments = [];
  String get name;

}