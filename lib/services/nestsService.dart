import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/services/firestoreItemService.dart';

class NestsService extends FirestoreItemService<Nest> {
  NestsService(FirebaseFirestore firestore) : super(firestore);

  @override
  Nest convertToFirestoreItem(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Nest.fromDocSnapshot(doc);
  }
}
