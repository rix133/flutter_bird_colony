import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/googleMapScreen.dart';

import '../../models/firestore/nest.dart';
import '../../models/measure.dart';

class MapCreateNest extends GoogleMapScreen {
  final FirebaseFirestore firestore;

  const MapCreateNest({Key? key, required this.firestore})
      : super(key: key, autoUpdateLoc: true);

  @override
  FirebaseFirestore get firestoreInstance => firestore;

  @override
  _MapCreateNestState createState() => _MapCreateNestState();
}

class _MapCreateNestState extends GoogleMapScreenState {
  Nest getNest(bool withDefaults, String? id) {
    Nest nest = Nest(
      coordinates: GeoPoint(0, 0),
      accuracy: "loading...",
      last_modified: DateTime.now(),
      discover_date: DateTime.now(),
      responsible: null,
      measures: [Measure.note()],
    );
    nest.coordinates = coordinates;
    nest.setAccuracy(accuracy);
    nest.last_modified = DateTime.now();
    if (withDefaults) {
      nest.id = id;
      nest.species = sps?.defaultSpecies;
      nest.responsible = sps?.userName;
    }
    return nest;
  }

  @override
  GestureDetector lastFloatingButton() {
    return GestureDetector(
      onLongPress: () {
        String? nextId;
        widget.firestoreInstance
            .collection('recent')
            .doc("nest")
            .get()
            .then((value) {
          if (value.data() != null) {
            int? next = int.tryParse(value.data()!['id']);
            if (next != null) {
              nextId = (next + 1).toString();
            }
            //reserve the id!?
            //lastId.set({'id': nest.id});
          }
          Navigator.pushNamed(context, '/createNest',
              arguments: getNest(true, nextId));
        });
      },
      child: FloatingActionButton(
        heroTag: "addNest",
        onPressed: () {
          Navigator.pushNamed(context, '/createNest',
              arguments: getNest(false, null));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

