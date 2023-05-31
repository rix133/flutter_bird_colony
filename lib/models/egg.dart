import 'package:cloud_firestore/cloud_firestore.dart';

class Egg {
  String? id;
  Timestamp discover_date;
  String responsible;
  String? ring;
  String status;
  List<Object>? changelogs;

  Egg({this.id,
    required this.discover_date,
    required this.responsible,
    required this.status,
    this.ring});

  @override
  factory Egg.fromQuerySnapshot(QueryDocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    return (Egg(
        id: snapshot.id,
        discover_date: json['discover_date'],
        responsible: json["responsible"],
        ring: json['ring'],
        status: json['status']
    ));
  }
}