import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakrarahu/models/experiment.dart';
import 'package:kakrarahu/models/firestore_item.dart';

class Egg implements FirestoreItem{
  String? id;
  Timestamp discover_date;
  String? responsible;
  String? ring;
  String status;
  List<Experiment> experiments = [];
  List<Object>? changelogs;

  Egg({this.id,
    required this.discover_date,
    required this.responsible,
    required this.status,
    this.ring});

  String get name => id ?? "New Egg";

  @override
  factory Egg.fromQuerySnapshot(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    return (Egg(
        id: snapshot.id,
        discover_date: json['discover_date'],
        responsible: json["responsible"],
        ring: json['ring'],
        status: json['status']
    ));
  }
  @override
  Future <bool> save({CollectionReference<Object?>? otherItems = null, bool allowOverwrite = false, type = "default"}) async {
    // TODO: implement save
    throw UnimplementedError();
  }

  @override
  Future <bool> delete({CollectionReference<Object?>? otherItems = null, bool soft = true, type = "default"}) async {
    throw UnimplementedError();
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