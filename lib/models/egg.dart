import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/experiment.dart';
import 'package:kakrarahu/models/firestore_item.dart';
import 'package:kakrarahu/models/nest.dart';
import 'package:kakrarahu/models/updateResult.dart';

class Egg implements FirestoreItem{
  String? id;
  DateTime discover_date;
  String? responsible;
  String? ring;
  String status;
  List<Experiment>? experiments = [];
  List<Object>? changelogs;

  Egg({this.id,
    required this.discover_date,
    required this.responsible,
    required this.status,
    this.ring});

  String get name => id ?? "New Egg";

  @override
  factory Egg.fromDocSnapshot(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    return (Egg(
        id: snapshot.id,
        discover_date: (json['discover_date'] as Timestamp).toDate(),
        responsible: json["responsible"],
        ring: json['ring'],
        status: json['status']
    ));
  }
  @override
  Future <UpdateResult> save({CollectionReference<Object?>? otherItems = null, bool allowOverwrite = false, type = "default"}) async {
    // TODO: implement save
    throw UnimplementedError();
  }

  @override
  Future <UpdateResult> delete({CollectionReference<Object?>? otherItems = null, bool soft = true, type = "default"}) async {
    throw UnimplementedError();
  }

  int getNr(){
    return(int.tryParse(id?.split(" ")[2] ?? "0") ?? 0);
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
      child: (Text("Egg " +
          getNr().toString() +
          " $status" +
          (ring != null
              ? "/" +
              ring!
              : ""))),
      onPressed: () {
        Navigator.pushNamed(context, "/eggs",
            arguments: {
              "sihtkoht": nest!.name,
              "egg": id,
            });
      },
      onLongPress: () {
        Navigator.pushNamed(
            context, "/editChick",
            arguments: {
              "pesa": nest!.name,
              "muna_nr": (id).toString(),
              "species": nest!.species,
              "age": "1"
            });
      },
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'discover_date': discover_date,
      'responsible': responsible,
      'ring': ring,
      'status': status
    };
  }
}