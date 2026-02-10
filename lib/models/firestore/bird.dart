import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/eggStatus.dart';
import 'package:flutter_bird_colony/models/experimentedItem.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/firestore/firestoreItem.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/firestoreItemMixin.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_bird_colony/models/updateResult.dart';
import 'package:flutter_bird_colony/utils/year.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bird_colony/design/filledIconButton.dart';

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

  Bird? prevBird;

  @override
  String get name => (color_band?.isNotEmpty ?? false) ? color_band! : band;

  @override
  String get itemName => "bird";

  String get current_nest =>
      nest ?? "";

  @override
  DateTime get created_date => ringed_date;

  Bird copy() {
    return Bird(
      id: this.id,
      ringed_date: this.ringed_date,
      band: this.band,
      ringed_as_chick: this.ringed_as_chick,
      color_band: this.color_band,
      responsible: this.responsible,
      nest_year: this.nest_year,
      species: this.species,
      last_modified: this.last_modified,
      age: this.age,
      nest: this.nest,
      egg: this.egg,
      experiments:
          List<Experiment>.from(this.experiments?.map((e) => e.copy()) ?? []),
      measures: List<Measure>.from(this.measures.map((e) => e.copy())),
    );
  }

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
      (nest?.isNotEmpty ?? false) ? ", nest: " + (nest ?? "unknown") : "";

  String get description =>
      "Ringed: ${DateFormat('d MMM yyyy').format(ringed_date)} $nestString, $species";

  getDetailsDialog(BuildContext context, FirebaseFirestore firestore) {
    return AlertDialog(
      backgroundColor: Colors.black87,
      title: Text("Bird details"),
      content: SingleChildScrollView(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Band: $band"),
          Text("Color band: ${color_band ?? "unknown"}"),
          Text("Ringed: ${DateFormat('d MMM yyyy').format(ringed_date)}"),
          Text("Nest: ${nest ?? "unknown"}"),
          Text("Species: ${species ?? "unknown"}"),
          Text("Responsible: ${responsible ?? "unknown"}"),
          Text("Age: ${age ?? "unknown"}"),
          Text(
              "Last modified: ${last_modified != null ? DateFormat('d MMM yyyy').format(last_modified!) : "unknown"}"),
          Text("Egg: ${egg ?? "unknown"}"),
          Text(
              "Experiments: ${experiments?.map((e) => e.name).join(", ") ?? "unknown"}"),
          Text("Measures: ${measures.map((e) => e.name).join(", ")}"),
        ],
      )),
      actions: [
        ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("close")),
        //download changelog Elevated icon button
        ElevatedButton.icon(
          key: Key("downloadChangelog"),
          icon: Icon(Icons.download),
          label: Text("Download changelog"),
          onPressed: () async {
            Navigator.pop(context);
            await FSItemMixin().downloadChangeLog(
                this.changeLog(firestore), "bird", firestore);
          },
        ),
      ],
    );
  }

  ListTile getListTile(BuildContext context, FirebaseFirestore firestore,
      {bool disabled = false, List<MarkerColorGroup> groups = const []}) {
    return ListTile(
      title: Text(name + (color_band != null ? ' ($band)' : "")),
      subtitle: Text(description),
      trailing: FilledIconButton(
        icon: Icons.edit,
        iconColor: Colors.black87,
        backgroundColor: Colors.grey,
        onPressed: () {
          Navigator.pushNamed(context, '/editBird', arguments: {'bird': this});
        },
      ),
      onTap: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return getDetailsDialog(context, firestore);
            });
      },
    );
  }

  @override
  Future<List<Bird>> changeLog(FirebaseFirestore firestore) async {
    return (firestore
        .collection("Birds")
        .doc(band)
        .collection("changelog")
        .get()
        .then((value) {
      List<Bird> birdList =
          value.docs.map((e) => Bird.fromDocSnapshot(e)).toList();
      birdList.sort((a, b) => b.last_modified!.compareTo(
          a.last_modified!)); // Sort by last_modified in descending order
      return birdList;
    }));
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
    //save the original database state at loading
    nbird.prevBird = nbird.copy();
    return nbird;
  }

  Future<Egg?> getEgg(FirebaseFirestore firestore) async {
    if (egg == null || nest == null || !ringed_as_chick) {
      return null;
    }
    if (egg == "" || nest == "") {
      return null;
    }
    String year = yearToNestCollectionName(ringed_date.year);
    return firestore
        .collection(year)
        .doc(nest)
        .collection("egg")
        .doc("$nest egg $egg")
        .get()
        .then((value) {
      if (!value.exists) {
        return null;
      }
      return Egg.fromDocSnapshot(value);
    });
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
      'last_modified': last_modified ?? DateTime.now(),
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

  Future<UpdateResult> _checkNestChange(
      CollectionReference itemCollection, Bird prevBird) async {
    //do this only if any of the relevant fields is changed and there is a nest
    if (nest != prevBird.nest ||
        band != prevBird.band ||
        color_band != prevBird.color_band) {
      if (prevBird.nest != null) {
        UpdateResult ur =
            await prevBird.updateNest(itemCollection, delete: true);
        if (!ur.success) {
          return ur;
        } else {
          return await updateNest(itemCollection);
        }
      }
    }
    return UpdateResult.saveOK(item: this);

  }

  Future<UpdateResult> _saveBirdToFirestore(CollectionReference birds, CollectionReference? nestsItemCollection) async {
    //remove empty measures
    measures.removeWhere((element) => element.value.isEmpty);
    // the modified date is assigned at write time
    last_modified = DateTime.now();

    if (prevBird != null) {
      //handle legacy birds
      if (prevBird!.last_modified == null) {
        //write the previous value to changelog just in case if it has no last_modified date
        ringed_as_chick = true;
        await birds
            .doc(band)
            .collection("changelog")
            .doc(ringed_date.toString())
            .set(prevBird!.toJson());
      }
      //handle nest change of parents or eggs on nests only if  the collection is set
      if (nestsItemCollection != null) {
        //check if the nest has changed and update the nest accordingly
        await _checkNestChange(nestsItemCollection, prevBird!);
      }
    } else {
      //its  a new bird
      if (id == null && nestsItemCollection != null) {
        await updateNest(nestsItemCollection);
      }
    }
    last_modified = DateTime.now();
    return(birds.doc(band).set(toJson()).then((value) => _saveToChangelog(birds)).then((value) => UpdateResult.saveOK(item: this))
        .catchError((error) => UpdateResult.error(message: error.toString())));

  }

  Future<void> _saveToChangelog(CollectionReference birds) async {
    await birds.doc(band).collection("changelog").doc(last_modified.toString()).set(toJson());
  }

  Future<UpdateResult> updateNest(CollectionReference nestsItemCollection,
      {bool delete = false}) async {
    if (nest?.isEmpty ?? true) {
      return UpdateResult.saveOK(item: this);
    } else if (!isChick()) {
      return await _updateNestParent(nestsItemCollection, delete: delete);
    } else {
      CollectionReference eggsCollection =
          nestsItemCollection.doc(nest).collection("egg");
      return await _updateNestChick(eggsCollection, delete: delete);
    }
  }

  Future<UpdateResult> _updateNestParent(
      CollectionReference nestsItemCollection,
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
      return UpdateResult.error(message: "Error updating nest parents");
    }
  }

  Future<UpdateResult> _updateNestChick(CollectionReference eggItemCollection,
      {bool delete = false}) async {
    if (egg == null && delete) {
      await eggItemCollection.doc("$nest chick ${band}").delete();
      return UpdateResult.saveOK(item: this);
    }
    if (egg == null) {
      Egg newEgg = Egg(
          id: "$nest chick $band",
          discover_date: prevBird?.ringed_date ?? ringed_date,
          last_modified: DateTime.now(),
          experiments: prevBird?.experiments ?? [],
          measures: [],
          responsible: responsible,
          ring: band,
          status: EggStatus("hatched"));
      await eggItemCollection.doc(newEgg.id).set(newEgg.toJson());
      return UpdateResult.saveOK(item: this);
    } else {
      String? newBand = band;
      if (delete) {
        newBand = null;
      }
      await eggItemCollection.doc("$nest egg $egg").update({
        'ring': newBand,
        'status': 'hatched',
        'responsible': responsible,
        'last_modified': DateTime.now()
      });
      return UpdateResult.saveOK(item: this);
    }
  }

  bool isChick({int? currentYear}) {
    final year = currentYear ?? DateTime.now().year;
    return (ringed_as_chick == true &&
            ringed_date.year == nest_year &&
            year == nest_year) &&
        (color_band?.isEmpty ?? true);
  }

  int ageInYears() {
    return ringed_as_chick ? (DateTime.now().year - ringed_date.year) : int.tryParse(age ?? "") ?? 0;
  }

  int ageInDays() {
    return ringed_as_chick
        ? (DateTime.now().difference(ringed_date).inDays)
        : 0;
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
    //check that the band has numbers
    if (band.isNotEmpty && !RegExp(r'[0-9]').hasMatch(band)) {
      return UpdateResult.error(message: "Band must contain numbers");
    }
    if (type == "parent" || type == "chick") {
      //handle only color ring birds i.e. uncaught parents
      if (band.isEmpty) {
        // it has a nest and a color band
        if (current_nest.isNotEmpty && name.isNotEmpty && otherItems != null) {
          //save only to nest parents not all birds
          return (await _updateNestParent(otherItems));
        }
        return UpdateResult.error(
            message: "Can't save bird without metal band");
      }
      CollectionReference birds =
          firestore.collection("Birds");

      //allow silent overwrites if the bird is saved before
      // and the band and nest have not changed
      if (prevBird != null && !allowOverwrite) {
        if (prevBird!.band == band && prevBird!.nest == nest) {
          allowOverwrite = true;
        }
      }

      if (allowOverwrite) {
        //if a band is changed overwrite the previous bird should never be allowed
        if (prevBird != null && prevBird!.band != band) {
          return UpdateResult.error(
              message: "Won't overwrite bird with a different band");
        }
        return await _saveOverwrite(firestore, otherItems, type);
      } else {
        return await birds.doc(band).get().then((value) async {
          if (!value.exists) {
            return await _saveOverwrite(firestore, otherItems, type);
          } else {
            //check if there is a previous bird and if the band has changed
            String prevNestMsg = "";
            if (prevBird != null) {
              String prevNest = prevBird!.nest ?? "";
              String prevNestYear = prevBird!.nest_year.toString();
              prevNestMsg = "\nPrevious nest: $prevNest (year: $prevNestYear)";
            }
            return UpdateResult.error(
                message: " Bird with this band already exists! $prevNestMsg");
          }
        });
      }
    }
    return UpdateResult.error(message: "Unknown type of bird: $type");
  }

  Future<UpdateResult> _saveOverwrite(FirebaseFirestore firestore,
      CollectionReference<Object?>? otherItems, String type) async {
    CollectionReference birds = firestore.collection("Birds");
    if (prevBird != null && prevBird!.band != band) {
      return await prevBird!
          .delete(firestore, otherItems: otherItems, type: type)
          .then((value) async {
        if (value.success) {
          return await _saveBirdToFirestore(birds, otherItems);
        } else {
          return value;
        }
      });
    } else {
      return await _saveBirdToFirestore(birds, otherItems);
    }
  }

  @override
  Future<UpdateResult> delete(FirebaseFirestore firestore,
      {CollectionReference<Object?>? otherItems = null,
      type = "parent"}) async {
    // delete from the nest as well if asked for
    if (otherItems != null) {
      await updateNest(otherItems, delete: true);
    }

    CollectionReference items = firestore.collection("Birds");
    //check if the item exists if misssing return early
    UpdateResult ur = await items.doc(id).get().then((doc)  {
      if (!doc.exists) {
        return UpdateResult.deleteOK(item: this);
      }
      return UpdateResult.error(message: "Bird found in the database");
    });
    if (ur.success) {
      return ur;
    }
    return FSItemMixin().deleteFirestoreItem(this, items);
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
  Future<List<List<CellValue>>> toExcelRows(
      {List<FirestoreItem>? otherItems}) async {
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

