import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/firestore/firestoreItem.dart';

abstract class FirestoreItemService<T extends FirestoreItem>
    extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  List<T>? _latestSnapshot;

  List<T> get items => _latestSnapshot ?? [];

  FirestoreItemService(this._firestore);

  StreamController<List<T>>? _controller;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String? currentCollectionName;

  List<String> multiCollection = [];

  CollectionReference<Map<String, dynamic>> _collection() {
    if (currentCollectionName == null)
      throw Exception("Collection name is not set");
    if (multiCollection.length == 2) {
      return _firestore
          .collection(multiCollection[0])
          .doc(currentCollectionName!)
          .collection(multiCollection[1]);
    } else
      return _firestore.collection(currentCollectionName!);
  }

  T convertToFirestoreItem(DocumentSnapshot<Map<String, dynamic>> doc);

  Stream<List<T>> watchItems(String collectionName) {
    if (_controller == null || currentCollectionName != collectionName) {
      currentCollectionName = collectionName;
      _controller = StreamController<List<T>>.broadcast();
      _subscription = _collection().snapshots().listen((snapshot) {
        _latestSnapshot =
            snapshot.docs.map((doc) => convertToFirestoreItem(doc)).toList();
        if (!_controller!.isClosed) {
          _controller!.sink.add(_latestSnapshot!);
        }
      });
    }
    return _controller!.stream;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller?.close();
    super.dispose();
  }

}
