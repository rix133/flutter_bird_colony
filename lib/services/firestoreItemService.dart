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
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _subscriptions = [];
  String? currentCollectionName;
  String? currentQueryKey;

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
    currentCollectionName = collectionName;
    return watchQuery(collectionName, _collection());
  }

  Stream<List<T>> watchQuery(
      String queryKey, Query<Map<String, dynamic>> query) {
    return watchQueries(queryKey, [query]);
  }

  Stream<List<T>> watchQueries(
      String queryKey, List<Query<Map<String, dynamic>>> queries) {
    if (_controller == null || currentQueryKey != queryKey) {
      currentQueryKey = queryKey;
      _latestSnapshot = null;
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
      _subscriptions.clear();
      _controller?.close();
      _controller = StreamController<List<T>>.broadcast();
      final controller = _controller!;
      final queryItems = List<List<T>>.generate(queries.length, (_) => []);

      void emitLatestSnapshot() {
        final byId = <String, T>{};
        final withoutId = <T>[];
        for (final items in queryItems) {
          for (final item in items) {
            final id = item.id;
            if (id == null || id.isEmpty) {
              withoutId.add(item);
            } else {
              byId[id] = item;
            }
          }
        }
        _latestSnapshot = [...byId.values, ...withoutId];
        if (!controller.isClosed) {
          controller.sink.add(_latestSnapshot!);
        }
      }

      for (int i = 0; i < queries.length; i++) {
        final index = i;
        _subscriptions.add(queries[index].snapshots().listen((snapshot) {
          queryItems[index] =
              snapshot.docs.map((doc) => convertToFirestoreItem(doc)).toList();
          emitLatestSnapshot();
        }));
      }
    }
    return _controller!.stream;
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _controller?.close();
    super.dispose();
  }
}
