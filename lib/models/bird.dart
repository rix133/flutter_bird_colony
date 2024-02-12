import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kakrarahu/models/experiment.dart';
import 'package:kakrarahu/models/firestore_item.dart';
import 'package:kakrarahu/models/measure.dart';

class Bird implements FirestoreItem {
  String? id;
  String? nest;
  int? nest_year;
  String? age;
  String band;
  String? color_band;
  String? responsible;
  String? species;
  DateTime ringed_date;
  DateTime? last_modified;
  String? egg;
  List<Measure>? measures = [];
  List<Experiment>? experiments = [];

  @override
  String get name => color_band ?? band;

  String get current_nest =>
      (nest_year == DateTime.now().year) ? (nest ?? "") : "";

  Bird(
      {this.id,
      required this.ringed_date,
      required this.band,
      this.color_band,
      this.responsible,
      this.nest_year,
      this.species,
      this.last_modified,
      this.experiments,
      this.age,
      this.nest,
      this.egg,
      this.measures});

  bool timeSpan(String range) {
    if (range == "All") {
      return (true);
    }
    if (range == "Today") {
      var today = DateTime.now().toIso8601String().split("T")[0];
      return this.ringed_date.toIso8601String().split("T")[0].toString() ==
          today;
    }
    if (range == "This year") {
      return this.ringed_date.year == DateTime.now().year;
    }
    int? rangeInt = int.tryParse(range);
    if (rangeInt != null) {
      return this.ringed_date.year == rangeInt;
    }

    return false;
  }
  String get nestString => nest_year == DateTime.now().year ? "nest: " + (nest ?? "unknown") : "";
  String get description =>
      "Ringed: ${DateFormat('d MMM yyyy').format(ringed_date)}, $nestString, $species";

  ListTile getListTile(BuildContext context) {
    return ListTile(
      title: Text(name + (color_band != null ? ' ($band)' : "")),
      subtitle: Text(description),
      trailing: IconButton(
        icon: Icon(Icons.edit, color: Colors.blue),
        onPressed: () {
          Navigator.pushNamed(context, '/editParent', arguments: this);
        },
      ),
      onTap: () {
        AlertDialog(title: Text("What should this do?"));
      },
    );
  }

  bool seenThisYear(bool chick) {
    if (chick || last_modified == null) {
      return this.ringed_date.year == DateTime.now().year;
    } else {
      return this.last_modified!.year == DateTime.now().year;
    }
  }

  bool people(String range, String me) {
    if (range == "Everybody") {
      return (true);
    }
    if (range == "Me") {
      return this.responsible == me;
    }
    return false;
  }

  @override
  factory Bird.fromQuerySnapshot(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    return (Bird(
      id: snapshot.id,
      ringed_date: (json['ringed_date'] as Timestamp).toDate(),
      band: json["band"] ?? '',
      color_band: json["color_band"] ?? null,
      responsible: json["responsible"] ?? null,
      egg: json['egg'] ?? null,
      species: json['species'] ?? null,
      nest: json['nest'] ?? null,
      nest_year: json['nest_year'] ?? DateTime.now().year,
      last_modified: json['last_modified'] != null
          ? (json['last_modified'] as Timestamp).toDate()
          : null,
      age: json['age'] ?? null,
      experiments: json['experiments'] ?? [],
      // provide a default value if 'experiments' does not exist
      measures: (json['measures'] as List<dynamic>?)
              ?.map((e) => measureFromJson(e))
              .toList() ??
          [], // provide a default value if 'measures' does not exist
    ));
  }

  Map<String, dynamic> toJson() {
    return {
      'ringed_date': ringed_date,
      'band': band,
      'color_band': color_band,
      'responsible': responsible,
      'species': species,
      'nest': nest,
      'nest_year': nest_year,
      'experiments': experiments,
      'last_modified': last_modified,
      'age': age,
      'egg': egg,
      'measures': measures?.map((e) => e.toJson()).toList(),
    };
  }

  Map<String, dynamic> toSimpleJson() {
    return {
      'band': band,
      'color_band': color_band,
    };
  }

  Future<bool> _write2Firestore(CollectionReference birds,
      CollectionReference nestsItemCollection, bool isParent) async {
    // take ony those measures where value is not empty
    if (measures != null) {
      measures = [];
    }
    if (nest != null) {
      if (nest!.isNotEmpty) {
        nestsItemCollection = isParent
            ? nestsItemCollection
            : nestsItemCollection.doc(nest).collection("eggs");
      }
    }

    measures = measures!.where((element) => element.value.isNotEmpty).toList();
    // the modified date is assigned at write time
    last_modified = DateTime.now();
    return (await birds
        .doc(band)
        .set(toJson())
        .whenComplete(() => birds
            .doc(band)
            .collection("changelog")
            .doc(last_modified.toString())
            .set(toJson()))
        .whenComplete(() => (nest?.isEmpty ?? true)
            ? true
            : isParent
                ? nestsItemCollection.doc(nest).update({
                    'parents': FieldValue.arrayUnion([toSimpleJson()])
                  })
                : nestsItemCollection
                    .doc("$nest egg $egg")
                    .set({'ring': band, 'status': 'hatched'}))
        .then((value) => true)
        .catchError((error) => false));
  }

  @override
  Future<bool> save(
      {CollectionReference<Object?>? otherItems = null,
      bool allowOverwrite = false,
      type = "parent"}) async {
    if (band.isEmpty && name.isEmpty) {
      return false;
    }
    if (type == "parent" || type == "chick") {
      bool isParent = (type == "parent");
      if (band.isEmpty) {
        // it has a nest and a color band
        if (current_nest.isNotEmpty && name.isNotEmpty && otherItems != null) {
          //show a snackbar saying that this is saved only under nest because metal band is missing
          SnackBar(
            content: Text(
                "Metal band is missing, accessible only under nest only",
                style: TextStyle(color: Colors.white)),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.red,
          );

          //save only to nest parents not all birds
          return (await otherItems
              .doc(isParent ? name : "$nest egg $egg")
              .set(isParent ? toJson() : {'ring': band, 'status': 'hatched'})
              .then((value) => true)
              .catchError((error) => false));
        }
        return false;
      }
      CollectionReference birds =
          FirebaseFirestore.instance.collection("Birds");

      if (allowOverwrite && otherItems != null) {
        return await _write2Firestore(birds, otherItems, isParent);
      } else if (otherItems != null) {
        return await birds.doc(band).get().then((value) {
          if (!value.exists) {
            return _write2Firestore(birds, otherItems, isParent);
          } else {
            Bird prevBird = Bird.fromQuerySnapshot(value);
            //this needs to be fixed only for birds ringed as chicks
            if (prevBird.last_modified == null) {
              //write the previous value to changelog just in case
              return (birds
                  .doc(band)
                  .collection("changelog")
                  .doc(ringed_date.toString())
                  .set(prevBird.toJson())
                  .then((value) => false));
            }

            return false;
          }
        });
      }
    }
    throw UnimplementedError();
  }

  @override
  Future<bool> delete(
      {CollectionReference<Object?>? otherItems = null,
      bool soft = true,
      type = "parent"}) async {
    // delete from the nest as well if asked for
    if (otherItems != null) {
      await otherItems
          .doc(nest)
          .update({
            'parents': FieldValue.arrayRemove([toSimpleJson()])
          })
          .then((value) => true)
          .catchError((error) => false);
    }
    CollectionReference items = FirebaseFirestore.instance.collection("Birds");
    if (!soft) {
      return await items
          .doc(id)
          .delete()
          .then((value) => true)
          .catchError((error) => false);
    } else {
      CollectionReference deletedCollection = FirebaseFirestore.instance
          .collection("deletedItems")
          .doc("Birds")
          .collection("deleted");

      //check if the item is already in deleted collection
      return deletedCollection.doc(id).get().then((doc) {
        if (doc.exists == false) {
          return deletedCollection
              .doc(id)
              .set(toJson())
              .then((value) => items.doc(id).delete().then((value) => true))
              .catchError((error) => false);
        } else {
          return deletedCollection
              .doc('${id}_${DateTime.now().toString()}')
              .set(toJson())
              .then((value) => items.doc(id).delete().then((value) => true))
              .catchError((error) => false);
        }
      }).catchError((error) => false);
    }
  }
}

Bird birdFromJson(Map<String, dynamic> json) {
  return Bird(
      ringed_date: (json['ringed_date'] as Timestamp).toDate(),
      band: json['band'],
      color_band: json['color_band']);
}
