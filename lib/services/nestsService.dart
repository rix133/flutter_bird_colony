import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';

class NestsService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  List<Nest>? _latestNestsSnapshot;

  List<Nest> get nests => _latestNestsSnapshot ?? [];

  NestsService(this._firestore);

  StreamController<List<Nest>>? _nestsController;
  String? currentCollectionName;

  Stream<List<Nest>> watchNests(String collectionName) {
    if (_nestsController == null || currentCollectionName != collectionName) {
      currentCollectionName = collectionName;
      _nestsController = StreamController<List<Nest>>.broadcast();
      _firestore.collection(collectionName).snapshots().listen((snapshot) {
        _latestNestsSnapshot =
            snapshot.docs.map((doc) => Nest.fromDocSnapshot(doc)).toList();
        _nestsController!.sink.add(_latestNestsSnapshot!);
      });
    }
    return _nestsController!.stream;
  }

  void dispose() {
    super.dispose();
  }
}
