import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kakrarahu/models/experimentedItem.dart';
import 'package:kakrarahu/models/firestore/experiment.dart';
import 'package:kakrarahu/models/firestore/firestoreItem.dart';
import 'package:kakrarahu/models/firestore/nest.dart';
import 'package:kakrarahu/models/firestoreItemMixin.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/models/updateResult.dart';

import '../markerColorGroup.dart';
import 'egg.dart';

class Bird extends ExperimentedItem implements FirestoreItem{
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

  @override
  String get name => (color_band?.isNotEmpty ?? false) ? color_band! : band;

  String get current_nest =>
      (nest_year == DateTime.now().year) ? (nest ?? "") : "";

  @override
  DateTime get created_date => ringed_date;

  Bird({
    this.id,
    required this.ringed_date,
    required this.band,
    required this.ringed_as_chick,
    this.color_band,
    this.responsible,
    this.nest_year,
    this.species,
    this.last_modified,
    this.age,
    this.nest,
    this.egg,
    List<Experiment>? experiments,
    required List<Measure> measures
  }) : super(experiments: experiments, measures: measures) {
    updateMeasuresFromExperiments(isChick() ? "chick" : "parent");
  }
  

  String getType() {
    return isChick() ? "chick" : "parent";
  }

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
      nest_year == DateTime.now().year ? ", nest: " + (nest ?? "unknown") : "";

  String get description =>
      "Ringed: ${DateFormat('d MMM yyyy').format(ringed_date)} $nestString, $species";

  ListTile getListTile(BuildContext context,
      {bool disabled = false, List<MarkerColorGroup> groups = const []}) {
    return ListTile(
      title: Text(name + (color_band != null ? ' ($band)' : "")),
      subtitle: Text(description),
      trailing: IconButton(
        icon: Icon(Icons.edit, color: Colors.black87),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.grey)),
        onPressed: () {
          Navigator.pushNamed(context, '/editBird',
              arguments: {'bird': this});
        },
      ),
      onTap: () {
        showDialog(context: context, builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black87,
            title: Text("Bird details"),
            content: Column(
              children: [
                Text("Band: $band"),
                Text("Color band: ${color_band ?? "unknown"}"),
                Text("Ringed: ${DateFormat('d MMM yyyy').format(ringed_date)}"),
                Text("Nest: ${nest ?? "unknown"}"),
                Text("Species: ${species ?? "unknown"}"),
                Text("Responsible: ${responsible ?? "unknown"}"),
                Text("Age: ${age ?? "unknown"}"),
                Text("Last modified: ${last_modified != null ? DateFormat('d MMM yyyy').format(last_modified!) : "unknown"}"),
                Text("Egg: ${egg ?? "unknown"}"),
                Text("Experiments: ${experiments?.map((e) => e.name).join(", ") ?? "unknown"}"),
                Text("Measures: ${measures.map((e) => e.name).join(", ")}"),
              ],
            ),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Close"))
            ],
          );
        });
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
  factory Bird.fromDocSnapshot(DocumentSnapshot<Object?> snapshot) {
    if(snapshot.data() == null) {
      throw Exception("Document does not exist");
    }
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    ExperimentedItem eitem = ExperimentedItem.fromJson(json);
    Bird nbird = Bird(
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
      experiments: eitem.experiments,
      // provide a default value if 'experiments' does not exist
      measures: eitem.measures, // provide a default value if 'measures' does not exist
    );
    //add measures from experiments to the bird
    nbird.updateMeasuresFromExperiments(nbird.isChick() ? "chick" : "parent");

    return nbird;
  }

  factory Bird.fromEgg(Egg egg) {
    return Bird(
        ringed_date: egg.discover_date,
        ringed_as_chick: true,
        band: egg.ring ?? "",
        color_band: "",
        responsible: egg.responsible ?? "",
        species: "",
        nest: egg.getNest(),
        nest_year: egg.discover_date.year,
        last_modified: egg.last_modified,
        age: "",
        egg: egg.getNr(),
        experiments: egg.experiments,
        measures: egg.measures);
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
      'experiments': experiments?.map((Experiment e) => e.toSimpleJson()).toList(),
      'last_modified': last_modified,
      'age': age,
      'egg': egg,
      'measures': measures.map((Measure e) => e.toJson()).toList(),
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
      return Bird.fromDocSnapshot(value);
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
    ringed_date =prevBird?.ringed_date ?? DateTime.now();
    last_modified = DateTime.now();
    return(birds.doc(band).set(toJson()).then((value) => _saveToChangelog(birds)).then((value) => UpdateResult.saveOK(item: this))
        .catchError((error) => UpdateResult.error(message: error.toString())));

  }

  Future<void> _saveToChangelog(CollectionReference birds) async {
    await birds.doc(band).collection("changelog").doc(last_modified.toString()).set(toJson());
  }

  Future<UpdateResult> _updateNest(CollectionReference nestsItemCollection, bool isParent) async {
    if (nest?.isEmpty ?? true) {
      return UpdateResult.saveOK(item: this);
    } else if (isParent) {
      return await updateNestParent(nestsItemCollection);
    } else {
      return await _updateNestEgg(nestsItemCollection);
    }
  }

  Future<UpdateResult> updateNestParent(CollectionReference nestsItemCollection,
      {bool delete = false}) async {
    try {
      Nest? nestObj = await nestsItemCollection.doc(nest).get().then((value) {
        if(!value.exists) {
          return null;
        }
        return Nest.fromDocSnapshot(value);
      });
      if (nestObj == null) {
        return UpdateResult.error(message: "Nest: $nest not found");
      }
      //search and replace the nest parents with the new one by band if exists, then by color band
      if(nestObj.parents != null) {
        bool hasBand = nestObj.parents!.any((element) => element.band == band && band.isNotEmpty);
        bool hasColorBand = nestObj.parents!.any((element) => element.color_band == color_band && (color_band?.isNotEmpty ?? false));
        if(hasBand || hasColorBand) {
          nestObj.parents!.removeWhere((element) => (element.band == band && band.isNotEmpty) || (element.color_band == color_band && (color_band?.isNotEmpty ?? false)));
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
      return(await nestsItemCollection.doc(nest).update({'parents': nestObj.parents!.map((e) => e.toSimpleJson()).toList()}).then((value) => UpdateResult.saveOK(item: this))
      );
    } catch (error) {
      return UpdateResult.error(message: "Error saving bird");
    }
  }

  bool isChick() {
    return (ringed_as_chick == true && ringed_date.year == nest_year && DateTime.now().year == nest_year) && (color_band?.isEmpty ?? true);
  }

  int ageInYears() {
    return ringed_as_chick ? (DateTime.now().year - ringed_date.year) : int.tryParse(age ?? "") ?? 0;
  }

  Future<UpdateResult> _updateNestEgg(CollectionReference eggItemCollection) async {
    if (egg == null) {
      await eggItemCollection.doc("$nest chick $band").set(Egg(
          discover_date: DateTime(1900),
          last_modified: DateTime.now(),
          experiments: experiments,
          measures: [],
          responsible: "unknown",
          ring: band,
          status: 'hatched').toJson());
      return UpdateResult.saveOK(item: this);
    } else {
      await eggItemCollection.doc("$nest egg $egg").update({'ring': band, 'status': 'hatched'});
    }
    return UpdateResult.saveOK(item: this);
  }

  Future<UpdateResult> _saveBird(CollectionReference birds, CollectionReference? nestsItemCollection, bool isParent) async {
    UpdateResult? ur;
    try {
        ur = await _saveBirdToFirestore(birds, nestsItemCollection);
        if(!ur.success) {
          return ur;
        }
      if(nestsItemCollection != null){
        ur = await _updateNest(nestsItemCollection, isParent);
        if(!ur.success) {
          return ur;
        }
      }
      return UpdateResult.saveOK(item: this);
    } catch (error) {
      return UpdateResult.error(message: "Error saving bird");
    }
  }


  Future<UpdateResult> _write2Firestore(CollectionReference birds,
      CollectionReference? nestsItemCollection, bool isParent) async {
    if (nest != null) {
      if (nest!.isNotEmpty && nestsItemCollection != null) {
        nestsItemCollection = isParent
            ? nestsItemCollection
            : nestsItemCollection.doc(nest).collection("egg");
      }
    }
    //remove empty measures
    measures.removeWhere((element) => element.value.isEmpty);
    // the modified date is assigned at write time
    last_modified = DateTime.now();
    return await _saveBird(birds, nestsItemCollection, isParent);
  }

  @override
  Future<UpdateResult> save(FirebaseFirestore firestore,
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
          firestore.collection("Birds");

      if (allowOverwrite) {
        return await _write2Firestore(birds, otherItems, isParent);
      } else {
        return await birds.doc(band).get().then((value) async {
          if (!value.exists) {
            return  await _write2Firestore(birds, otherItems, isParent);
          } else {
            return UpdateResult.error(message: " Bird with this band already exists! ");
          }
        });
      }
    }
    return UpdateResult.error(message: "Unknown type");
  }

  @override
  Future<UpdateResult> delete(FirebaseFirestore firestore,
      {CollectionReference<Object?>? otherItems = null,
      bool soft = true,
      type = "parent"}) async {
    // delete from the nest as well if asked for
    if (otherItems != null && type == "parent") {
      await updateNestParent(otherItems, delete: true);
    }
    CollectionReference items = firestore.collection("Birds");
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
      CollectionReference deletedCollection = firestore
          .collection("deletedItems")
          .doc("Birds")
          .collection("deleted");

      //check if the item is already in deleted collection

      return FSItemMixin().deleteFiresoreItem(this, items, deletedCollection);
    }
  }

  @override
  List<TextCellValue> toExcelRowHeader() {
    List<TextCellValue> baseItems = [
      TextCellValue('band'),
      TextCellValue('color_band'),
      TextCellValue("type"),
      TextCellValue('nest'),
      TextCellValue('nest_year'),
      TextCellValue('age_years'),
      TextCellValue('responsible'),
      TextCellValue('species'),
      TextCellValue('ringed_date'),
      TextCellValue('ringed_as_chick'),
      TextCellValue('last_modified'),
      TextCellValue('egg')
    ];
    // Add more headers as per your requirements

    Map<String, List<Measure>> measuresMap = getMeasuresMap();
    List<TextCellValue> measureItems = measuresMap
        .map((key, value) => MapEntry(key, value.first.toExcelRowHeader()))
        .values
        .expand((e) => e)
        .toList();

    return [...baseItems, ...measureItems];
  }

  @override
  Future<List<List<CellValue>>> toExcelRows() async {
    List<CellValue> baseItems = [
      TextCellValue(band),
      TextCellValue(color_band ?? ""),
      TextCellValue(getType()),
      TextCellValue(nest ?? ""),
      IntCellValue(nest_year ?? 0),
      IntCellValue(ageInYears()),
      TextCellValue(responsible ?? ""),
      TextCellValue(species ?? ""),
      DateCellValue(year: ringed_date.year, month: ringed_date.month, day: ringed_date.day),
      BoolCellValue(ringed_as_chick),
      last_modified != null ? DateTimeCellValue.fromDateTime(last_modified!) : TextCellValue(""),
      TextCellValue(egg ?? ""),
      // Add more row data as per your requirements
    ];

    List<List<CellValue>> rows = addMeasuresToRow(baseItems);

    return rows;
  }
  factory Bird.fromJson(Map<String, dynamic> json) {
    return Bird(
        ringed_date: (json['ringed_date'] as Timestamp).toDate(),
        ringed_as_chick: json['ringed_as_chick'] ?? true,
        band: json['band'],
        measures: (json['measures'] as List<dynamic>?)
            ?.map((e) => Measure.fromJson(e))
            .toList() ??
            [],
        color_band: json['color_band']);
  }

}

