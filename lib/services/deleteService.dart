
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakrarahu/models/firestore_item.dart';
import 'package:kakrarahu/models/updateResult.dart';

Future<UpdateResult> deleteFiresoreItem(FirestoreItem item, CollectionReference from, CollectionReference to) async {
  return(to.doc(item.id).get().then((doc) {
    //check if the item is already in deleted collection
    if (doc.exists == false) {
      return to
          .doc(item.id)
          .set(item.toJson())
          .then((value) => from.doc(item.id).delete().then((value) => UpdateResult.deleteOK(item: item)))
          .catchError((error) => UpdateResult.error(message: error.toString()));
    } else {
      return to
          .doc('${item.id}_${DateTime.now().toString()}')
          .set(item.toJson())
          .then((value) => from.doc(item.id).delete().then((value) => UpdateResult.deleteOK(item: item)))
          .catchError((error) => UpdateResult.error(message: error.toString()));
    }
  }).catchError((error) => UpdateResult.error(message: error.toString())));
}