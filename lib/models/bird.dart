import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kakrarahu/models/experiment.dart';
import 'package:kakrarahu/models/experimented_item.dart';
import 'package:kakrarahu/models/firestore_item.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/models/nest.dart';
import 'package:kakrarahu/models/updateResult.dart';

class Bird implements FirestoreItem, ExperimentedItem {
  String? id;
  String? nest;
  int? nest_year;
  String? age;
  String band;
  String? color_band;
  String? responsible;
  String? species;
  DateTime ringed_date;
  bool ringed_as_chick = true;
  DateTime? last_modified;
  String? egg;
  List<Measure>? measures = [];
  List<Experiment>? experiments = [];

  @override
  String get name => (color_band?.isNotEmpty ?? false) ? color_band! : band;

  String get current_nest =>
      (nest_year == DateTime.now().year) ? (nest ?? "") : "";

  Bird(
      {this.id,
      required this.ringed_date,
      required this.band,
      required this.ringed_as_chick,
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

  String get nestString =>
      nest_year == DateTime.now().year ? "nest: " + (nest ?? "unknown") : "";

  String get description =>
      "Ringed: ${DateFormat('d MMM yyyy').format(ringed_date)}, $nestString, $species";

  ListTile getListTile(BuildContext context) {
    return ListTile(
      title: Text(name + (color_band != null ? ' ($band)' : "")),
      subtitle: Text(description),
      trailing: IconButton(
        icon: Icon(Icons.edit, color: Colors.blue),
        onPressed: () {
          Navigator.pushNamed(context, '/editParent',
              arguments: {'bird': this});
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
      ringed_as_chick: json["ringed_as_chick"] ?? true,
      band: json["band"] ?? '',
      color_band: json["color_band"] ?? null,
      responsible: json["responsible"] ?? null,
      egg: json['egg'] ?? null,
      species: json['species'] ?? null,
      nest: json['nest'] ?? null,
      nest_year:
          json['nest_year'] ?? (json['ringed_date'] as Timestamp).toDate().year,
      last_modified: json['last_modified'] != null
          ? (json['last_modified'] as Timestamp).toDate()
          : null,
      age: json['age'] ?? null,
      experiments: (json['experiments'] as List<dynamic>?)
              ?.map((e) => experimentFromJson(e))
              .toList() ??
          [],
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
      'ringed_as_chick': ringed_as_chick,
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
      'measures': measures?.map((Measure e) => e.toJson()).toList(),
    };
  }

  Map<String, dynamic> toSimpleJson() {
    return {
      'ringed_date': ringed_date,
      'band': band,
      'color_band': color_band,
    };
  }

  Future<UpdateResult> _checkNestChange(CollectionReference? nestsItemCollection, Bird prevBird) async {
    if (nest != null && nest != prevBird.nest && nestsItemCollection != null) {
      if (prevBird.nest != null) {
        return(prevBird.updateNestParent(nestsItemCollection, delete: true));
      }
    }
    return UpdateResult.saveOK(item: this);

  }

  Future<UpdateResult> _saveBirdToFirestore(CollectionReference birds, CollectionReference? nestsItemCollection) async {
    Bird? prevBird = await birds.doc(band).get().then((value) {
      if (!value.exists) {
        return null;
      }
      return Bird.fromQuerySnapshot(value);
    });
    if (prevBird != null) {
      //handle legacy birds
      if (prevBird.last_modified == null) {
        //write the previous value to changelog just in case
        ringed_as_chick = true;
        await birds
            .doc(band)
            .collection("changelog")
            .doc(ringed_date.toString())
            .set(prevBird.toJson());
      }
      //handle nest change of parents on nests
      await _checkNestChange(nestsItemCollection, prevBird);
    }
    ringed_date =prevBird?.ringed_date ?? ringed_date;
    await birds.doc(band).set(toJson());
    await _saveToChangelog(birds);
    return UpdateResult.saveOK(item: this);
  }

  Future<void> _saveToChangelog(CollectionReference birds) async {
    await birds.doc(band).collection("changelog").doc(last_modified.toString()).set(toJson());
  }

  Future<UpdateResult> _updateNest(CollectionReference nestsItemCollection, bool isParent) async {
    if (nest?.isEmpty ?? true) {
      return UpdateResult.saveOK(item: this);
    } else if (isParent) {
      return updateNestParent(nestsItemCollection);
    } else {
      return _updateNestEgg(nestsItemCollection);
    }
  }

  Future<UpdateResult> updateNestParent(CollectionReference nestsItemCollection,
      {bool delete = false}) async {
    try {
      Nest? nestObj = await nestsItemCollection.doc(nest).get().then((value) {
        if(!value.exists) {
          return null;
        }
        return Nest.fromQuerySnapshot(value);
      });
      if (nestObj == null) {
        return UpdateResult.error(message: "Nest: $nest not found");
      }
      //search and replace the nest parents with the new one by band if exists, then by color band
      if(nestObj.parents != null) {
        bool hasBand = nestObj.parents!.any((element) => element.band == band);
        bool hasColorBand = nestObj.parents!.any((element) => element.color_band == color_band);
        if(hasBand) {
          nestObj.parents!.removeWhere((element) => element.band == band);
        } else if(hasColorBand) {
          nestObj.parents!.removeWhere((element) => element.color_band == color_band);
        }
        //add the new parent
        if(delete == false) {
          nestObj.parents!.add(this);
        }
      } else {
        if(delete == false) {
          nestObj.parents = [this];
        }
      }
      // update the nest with the new parents
      await nestsItemCollection.doc(nest).update({
        'parents': nestObj.parents!.map((e) => e.toSimpleJson()).toList()
      });
      return UpdateResult.saveOK(item: this);
    } catch (error) {
      return UpdateResult.error(message: "Error saving bird");
    }
  }

  Future<UpdateResult> _updateNestEgg(CollectionReference nestsItemCollection) async {
    await nestsItemCollection.doc("$nest egg $egg").set({'ring': band, 'status': 'hatched'});
    return UpdateResult.saveOK(item: this);
  }

  Future<UpdateResult> _saveBird(CollectionReference birds, CollectionReference? nestsItemCollection, bool isParent) async {
    try {
      await _saveBirdToFirestore(birds, nestsItemCollection);
      if(nestsItemCollection != null){
        await _updateNest(nestsItemCollection, isParent);
      }
      return UpdateResult.saveOK(item: this);
    } catch (error) {
      return UpdateResult.error(message: "Error saving bird");
    }
  }


  Future<UpdateResult> _write2Firestore(CollectionReference birds,
      CollectionReference? nestsItemCollection, bool isParent) async {
    // take ony those measures where value is not empty
    if (nest != null) {
      if (nest!.isNotEmpty && nestsItemCollection != null) {
        nestsItemCollection = isParent
            ? nestsItemCollection
            : nestsItemCollection.doc(nest).collection("eggs");
      }
    }
    measures = measures?.where((Measure m) => m.value.isNotEmpty).toList() ?? [];
    // the modified date is assigned at write time
    last_modified = DateTime.now();
    return await _saveBird(birds, nestsItemCollection, isParent);
  }

  @override
  Future<UpdateResult> save(
      {CollectionReference<Object?>? otherItems = null,
      bool allowOverwrite = false,
      type = "parent"}) async {
    if (band.isEmpty && name.isEmpty) {
      return UpdateResult.error(
          message: "Can't save bird without metal band and color band");
    }
    if (type == "parent" || type == "chick") {
      bool isParent = (type == "parent");
      if (band.isEmpty) {
        // it has a nest and a color band
        if (current_nest.isNotEmpty && name.isNotEmpty && otherItems != null) {
          //save only to nest parents not all birds
          return (await _updateNest(otherItems, isParent));
        }
        return UpdateResult.error(
            message: "Can't save bird without metal band");
      }
      CollectionReference birds =
          FirebaseFirestore.instance.collection("Birds");

      if (allowOverwrite) {
        return await _write2Firestore(birds, otherItems, isParent);
      } else {
        return await birds.doc(band).get().then((value) {
          if (!value.exists) {
            return _write2Firestore(birds, otherItems, isParent);
          } else {
            return UpdateResult.error(message: " Bird with this band already exists! ");
          }
        });
      }
    }
    throw UnimplementedError();
  }

  @override
  Future<UpdateResult> delete(
      {CollectionReference<Object?>? otherItems = null,
      bool soft = true,
      type = "parent"}) async {
    // delete from the nest as well if asked for
    if (otherItems != null && type == "parent") {
      await updateNestParent(otherItems, delete: true);
    }
    CollectionReference items = FirebaseFirestore.instance.collection("Birds");
    //check if the item exists
    UpdateResult ur = await items.doc(id).get().then((doc)  {
      if (!doc.exists) {
        return UpdateResult.deleteOK(item: this);
      }
      return UpdateResult.error(message: "Bird found in the database");
    });
    if (ur.success) {
      return ur;
    }
    if (!soft) {
      return await items
          .doc(id)
          .delete()
          .then((value) => UpdateResult.deleteOK(item: this))
          .catchError((error) => UpdateResult.error(message: error.toString()));
    } else {
      CollectionReference deletedCollection = FirebaseFirestore.instance
          .collection("deletedItems")
          .doc("Birds")
          .collection("deleted");

      //check if the item is already in deleted collection
      return deletedCollection.doc(id).get().then((doc) {
        if (doc.exists == false) {
          return deletedCollection.doc(id).set(toJson()).then((value) => items
              .doc(id)
              .delete()
              .then((value) => UpdateResult.deleteOK(item: this))
              .catchError((error) => UpdateResult.error(message: error.toString())));
        } else {
          return deletedCollection
              .doc('${id}_${DateTime.now().toString()}')
              .set(toJson())
              .then((value) => items
                  .doc(id)
                  .delete()
                  .then((value) => UpdateResult.deleteOK(item: this))
                  .catchError((error) => UpdateResult.error(message: error)));
        }
      }).catchError((error) => UpdateResult.error(message: error));
    }
  }
}

Bird birdFromJson(Map<String, dynamic> json) {
  return Bird(
      ringed_date: (json['ringed_date'] as Timestamp).toDate(),
      ringed_as_chick: json['ringed_as_chick'] ?? true,
      band: json['band'],
      color_band: json['color_band']);
}
