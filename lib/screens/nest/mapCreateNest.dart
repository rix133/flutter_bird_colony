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
  Nest nest = Nest(
    coordinates: GeoPoint(0, 0),
    accuracy: "loading...",
    last_modified: DateTime.now(),
    discover_date: DateTime.now(),
    responsible: null,
    measures: [Measure.note()],
  );

  updateNest(bool withDefaults) {
    nest.coordinates = coordinates;
    nest.setAccuracy(accuracy);
    nest.last_modified = DateTime.now();
    if (withDefaults) {
      nest.species = sps?.defaultSpecies;
      nest.responsible = sps?.userName;
    }
  }

  @override
  GestureDetector lastFloatingButton() {
    return GestureDetector(
      onLongPress: () {
        widget.firestoreInstance
            .collection('recent')
            .doc("nest")
            .get()
            .then((value) {
          if (value.data() != null) {
            int? next = int.tryParse(value.data()!['id']);
            if (next != null) {
              nest.id = (next + 1).toString();
            }
            //reserve the id!?
            //lastId.set({'id': nest.id});
          }
          updateNest(true);
          Navigator.pushNamed(context, '/createNest', arguments: nest);
        });
      },
      child: FloatingActionButton(
        heroTag: "addNest",
        onPressed: () {
          updateNest(false);
          Navigator.pushNamed(context, '/createNest', arguments: nest);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

