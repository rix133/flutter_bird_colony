
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakrarahu/models/experiment.dart';
import 'package:kakrarahu/models/updateResult.dart';

abstract class FirestoreItem{

  //ListTile getListTile(void Function(String?) removeFun,
  //    void Function(void Function()) setState, BuildContext context);
  Map<String, dynamic> toJson();

  Future <UpdateResult> save({CollectionReference<Object?>? otherItems = null, bool allowOverwrite = false, String type = "default"});

  Future <UpdateResult> delete({CollectionReference<Object?>? otherItems = null, bool soft = true, String type = "default"});


  String? id;
  String? responsible;
  String get name;

}