//import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirestoreItem{

  //ListTile getListTile(void Function(String?) removeFun,
  //    void Function(void Function()) setState, BuildContext context);
  Map<String, dynamic> toJson();

  Future <bool> save(CollectionReference items, bool allowOverwrite);

  String? id;
  String? responsible;
  String get name;

}