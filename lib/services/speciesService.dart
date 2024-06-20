import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/services/firestoreItemService.dart';

class SpeciesService extends FirestoreItemService<Species> {
  SpeciesService(FirebaseFirestore firestore) : super(firestore);

  @override
  List<String> multiCollection = ['settings', 'species'];

  @override
  Species convertToFirestoreItem(DocumentSnapshot<Object?> doc) {
    return Species.fromDocSnapshot(doc);
  }
}
