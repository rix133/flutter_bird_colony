import 'package:cloud_firestore/cloud_firestore.dart';

class LocalUser{
  String email;
  bool isAdmin = false;
  String name;

  LocalUser({
    required this.email,
    this.isAdmin = false,
    required this.name,
  });

  factory LocalUser.fromDocSnapshot(DocumentSnapshot<Object?> doc){
    Map<String, dynamic> data=  doc.data() as Map<String, dynamic>;
    return LocalUser(
      email: doc.id,
      isAdmin: data['isAdmin'],
      name: data['name'] ?? '',
    );
  }
}