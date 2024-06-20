import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/services/firestoreItemService.dart';

class NestsService extends FirestoreItemService<Bird> {
  NestsService(FirebaseFirestore firestore) : super(firestore);

  @override
  Bird convertToFirestoreItem(DocumentSnapshot<Object?> doc) {
    return Bird.fromDocSnapshot(doc);
  }
}
