import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/services/firestoreItemService.dart';

class ExperimentsService extends FirestoreItemService<Experiment> {
  ExperimentsService(FirebaseFirestore firestore) : super(firestore);

  @override
  Experiment convertToFirestoreItem(DocumentSnapshot<Object?> doc) {
    return Experiment.fromDocSnapshot(doc);
  }
}
