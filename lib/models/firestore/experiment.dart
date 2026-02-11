import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/experimentedItem.dart';
import 'package:flutter_bird_colony/models/firestore/firestoreItem.dart';
import 'package:flutter_bird_colony/models/firestoreItemMixin.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_bird_colony/models/updateResult.dart';
import 'package:flutter_bird_colony/utils/year.dart';
import 'package:flutter_bird_colony/design/filledIconButton.dart';
import 'package:flutter_bird_colony/design/changelogRestoreDialog.dart';
import 'package:provider/provider.dart';

import '../../services/sharedPreferencesService.dart';
import '../markerColorGroup.dart';
import 'bird.dart';
import 'nest.dart';

class Experiment implements FirestoreItem {
  String? id;
  String name = "New Experiment";
  String? description;
  String? responsible;
  Color color = Colors.grey;
  int? year = DateTime.now().year;
  List<String>? nests = [];
  List<String>? birds = [];
  List<Measure> measures = [];
  String type = "nest";
  DateTime? last_modified;
  DateTime? created = DateTime.now();

  List<String> previousNests = [];
  List<String> previousBirds = [];

  Experiment copy() {
    return Experiment(
        id: id,
        name: name,
        description: description,
        responsible: responsible,
        year: year,
        nests: List.from(nests ?? []),
        birds: List.from(birds ?? []),
        type: type,
        measures: List.from(measures.map((m) => m.copy())),
        color: color,
        last_modified: last_modified,
        created: created);
  }

  Experiment(
      {this.id,
      required this.name,
      this.description,
      this.responsible,
      this.year,
      this.nests,
      this.type = "nest",
      this.measures = const [],
      this.birds,
      this.color = Colors.blue,
      this.last_modified,
      this.created});

  @override
  DateTime get created_date => created ?? DateTime(1900);

  Experiment.fromDocSnapshot(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    id = snapshot.id;
    name = json['name'] ?? "Untitled experiment";
    description = json['description'];
    responsible = json['responsible'];
    year = json['year'];
    measures = (json['measures'] as List<dynamic>?)
            ?.map((e) => Measure.fromJson(e))
            .toList() ??
        [];
    nests = List<String>.from(json['nests'] ?? []);
    birds = List<String>.from(json['birds'] ?? []);
    type = json['type'] ?? "nest";
    color = Color(int.parse(json['color']));
    last_modified = (json['last_modified'] as Timestamp).toDate();
    created = (json['created'] as Timestamp).toDate();
    previousBirds = List.from(birds ?? []);
    previousNests = List.from(nests ?? []);
  }

  Map<String, dynamic> toSimpleJson() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32().toString(),
      'measures': measures.map((e) => e.toFormJson()).toList()
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'responsible': responsible,
      'year': year,
      'nests': nests,
      'birds': birds,
      'type': type,
      'color': color.toARGB32().toString(),
      'last_modified': last_modified,
      'measures': measures.map((e) => e.toJson()).toList(),
      'created': created
    };
  }

  bool hasNests() {
    if (nests != null) {
      if (nests!.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool hasBirds() {
    if (birds != null) {
      if (birds!.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Column getItemsList(BuildContext context, Function setState) {
    List<Padding> items = [];
    if (hasNests()) {
      items.addAll(nests
              ?.map((e) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                  child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(5)),
                      child: ListTile(
                        title: Text('Nest ID: $e'),
                        onTap: gotoNest(e, context),
                        trailing: IconButton(
                          icon: Icon(Icons.close, color: Colors.redAccent),
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all<Color>(Colors.white60),
                          ),
                          onPressed: () {
                            setState(() {
                              nests!.remove(e);
                            });
                          },
                        ),
                      ))))
              .toList() ??
          []);
    }
    if (hasBirds()) {
      items.addAll(birds
              ?.map((e) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                  child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(5)),
                      child: ListTile(
                        title: Text('Bird ID: $e'),
                        onTap: gotoBird(e, context),
                        trailing: IconButton(
                          icon: Icon(Icons.close, color: Colors.redAccent),
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all<Color>(Colors.white60),
                          ),
                          onPressed: () {
                            setState(() {
                              birds!.remove(e);
                            });
                          },
                        ),
                      ))))
              .toList() ??
          []);
    }
    return Column(
      children: items,
    );
  }

  @override
  Future<List<Experiment>> changeLog(FirebaseFirestore firestore) async {
    return firestore
        .collection('experiments')
        .doc(id)
        .collection('changelog')
        .get()
        .then((value) {
      List<Experiment> experiments =
          value.docs.map((e) => Experiment.fromDocSnapshot(e)).toList();
      experiments.sort((a, b) => b.last_modified!.compareTo(a.last_modified!));
      return experiments;
    });
  }

  gotoNest(String nest, BuildContext context) {
    return () => {
          Navigator.pushNamed(context, '/editNest',
              arguments: {'nest_id': nest, 'year': year})
        };
  }

  List<UpdateResult> validate(SharedPreferencesService? sps,
      {List<FirestoreItem> otherItems = const []}) {
    return [];
  }

  gotoBird(String band, BuildContext context) {
    return () => {
          Navigator.pushNamed(context, "/editBird",
              arguments: {'bird_id': band})
        };
  }

  getDetailsDialog(BuildContext context, FirebaseFirestore firestore) {
    final isAdmin =
        Provider.of<SharedPreferencesService>(context, listen: false).isAdmin;
    return AlertDialog(
      backgroundColor: Colors.black87,
      title: Text("Experiment Details"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Name: $name"),
          Text("Description: ${description ?? ""}"),
          Text("Responsible: ${responsible ?? ""}"),
          Text("Year: ${year ?? ""}"),
          Text("Type: $type"),
          Text("Last Modified: ${last_modified?.toIso8601String() ?? ""}"),
          Text("Created: ${created?.toIso8601String() ?? ""}"),
          Text("Nests: ${nests?.join(", ") ?? ""}"),
          Text("Birds: ${birds?.join(", ") ?? ""}"),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("close"),
        ),
        //download changelog Elevated icon button
        ElevatedButton.icon(
          key: Key("downloadChangelog"),
          icon: Icon(Icons.download),
          label: Text("Download changelog"),
          onPressed: () async {
            Navigator.pop(context);
            await FSItemMixin().downloadChangeLog(
                this.changeLog(firestore), "experiment", firestore);
          },
        ),
        if (isAdmin)
          ElevatedButton.icon(
            icon: Icon(Icons.restore),
            label: Text("Restore version"),
            onPressed: () async {
              Navigator.pop(context);
              if (id == null) {
                return;
              }
              await RestoreFromChangelogDialog.show(
                context,
                itemRef: firestore.collection('experiments').doc(id),
                title: "Restore experiment $name",
              );
            },
          ),
      ],
    );
  }

  dispose() {
    measures.forEach((m) {
      m.dispose();
    });
  }

  String get titleString =>
      '$name${description?.isNotEmpty == true ? ' - $description' : ''}';

  Widget getListTile(BuildContext context, FirebaseFirestore firestore,
      {bool disabled = false, List<MarkerColorGroup> groups = const []}) {
    String subtitleNests = hasNests() ? "Nests: " + nests!.join(", ") : "";
    String subtitleBirds = hasBirds() ? "Birds: " + birds!.join(", ") : "";
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      child: ListTile(
        title: Text(titleString, style: TextStyle(fontSize: 20)),
        subtitle: Text(subtitleNests + subtitleBirds,
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        onTap: () {
          showDialog(
              context: context,
              builder: (BuildContext context) =>
                  getDetailsDialog(context, firestore));
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledIconButton(
              icon: Icons.map,
              iconColor: Colors.black87,
              backgroundColor: Colors.grey,
              onPressed: () {
                showNestMap(context);
              },
            ),
            FilledIconButton(
              icon: Icons.edit,
              iconColor: Colors.black,
              backgroundColor: Colors.white60,
              onPressed: () {
                Navigator.pushNamed(context, '/editExperiment',
                    arguments: this);
              },
            ),
          ],
        ),
      ),
    );
  }

  void showNestMap(BuildContext context) {
    Navigator.pushNamed(context, '/mapNests',
        arguments: {'nest_ids': nests, 'year': year});
  }

  Future<UpdateResult> _updateNestCollection(
      FirebaseFirestore firestore, List<String>? items,
      {bool delete = false}) async {
    CollectionReference nestCollection = firestore
        .collection(yearToNestCollectionName(year ?? DateTime.now().year));
    if (items != null) {
      Nest n;
      for (String i in items) {
        await nestCollection.doc(i).get().then((DocumentSnapshot value) => {
              if (value.exists)
                {
                  n = Nest.fromDocSnapshot(value),
                  n.experiments = n.experiments
                      ?.where((element) => element.id != id)
                      .toList(),
                  if (!delete)
                    {
                      n.experiments?.add(this),
                    },
                  nestCollection.doc(i).update({
                    'experiments':
                        n.experiments?.map((e) => e.toSimpleJson()).toList()
                  })
                }
            });
      }
    }
    return UpdateResult.saveOK(item: this);
  }

  Future<UpdateResult> _updateBirdsCollection(
      FirebaseFirestore firestore, List<String>? items,
      {bool delete = false}) async {
    CollectionReference birdCollection = firestore.collection("Birds");
    if (items != null) {
      Bird b;
      for (String i in items) {
        await birdCollection.doc(i).get().then((DocumentSnapshot value) => {
              if (value.exists)
                {
                  b = Bird.fromDocSnapshot(value),
                  b.experiments = b.experiments
                      ?.where((element) => element.id != id)
                      .toList(),
                  if (!delete)
                    {
                      b.experiments?.add(this),
                    },
                  birdCollection.doc(i).update({
                    'experiments':
                        b.experiments?.map((e) => e.toSimpleJson()).toList()
                  })
                }
            });
      }
    }
    return UpdateResult.saveOK(item: this);
  }

  @override
  Future<UpdateResult> delete(FirebaseFirestore firestore,
      {CollectionReference<Object?>? otherItems = null,
      String type = "default"}) {
    CollectionReference expCollection = firestore.collection('experiments');
    _updateNestCollection(firestore, previousNests, delete: true);
    _updateBirdsCollection(firestore, previousBirds, delete: true);

    return FSItemMixin().deleteFirestoreItem(this, expCollection);
  }

  @override
  Future<UpdateResult> save(FirebaseFirestore firestore,
      {CollectionReference<Object?>? otherItems = null,
      bool allowOverwrite = false,
      String type = "default"}) {
    CollectionReference expCollection = firestore.collection('experiments');

    last_modified = DateTime.now();
    //remove duplicate nests
    if (nests != null) {
      nests = nests!.toSet().toList();
    }
    if (birds != null) {
      birds = birds!.toSet().toList();
    }
    //get items that are missing from otherdata but exist in previousOtherItems
    List<String> deletedNests =
        previousNests.where((element) => !nests!.contains(element)).toList();
    List<String> deletedBirds =
        previousBirds.where((element) => !birds!.contains(element)).toList();

    if (id == null) {
      created = DateTime.now();
      id = created!.toIso8601String();
    }

    //save the experiment data to nests or birds
    return _updateNestCollection(firestore, nests, delete: false)
        .then(
            (v) => _updateNestCollection(firestore, deletedNests, delete: true))
        .then((v) => _updateBirdsCollection(firestore, birds, delete: false))
        .then((v) =>
            _updateBirdsCollection(firestore, deletedBirds, delete: true))
        .then((v) => expCollection
            .doc(id)
            .set(toJson())
            .then((value) => FSItemMixin().saveChangeLog(this, expCollection))
            .then((value) => UpdateResult.saveOK(item: this)))
        .catchError(
            (onError) => UpdateResult.error(message: onError.toString()));
  }

  @override
  List<TextCellValue> toExcelRowHeader() {
    List<TextCellValue> baseHeader = [
      TextCellValue('experiment_name'),
      TextCellValue('experiment_description'),
      TextCellValue('experiment_responsible'),
      TextCellValue('experiment_year'),
      TextCellValue('experiment_type'),
      TextCellValue('experiment_last_modified'),
      TextCellValue('experiment_created'),
      // Add more headers as per your requirements
    ];
    if (hasNests()) {
      baseHeader.add(TextCellValue('nest'));
    }
    if (hasBirds()) {
      baseHeader.add(TextCellValue('bird'));
    }
    return baseHeader;
  }

  @override
  Future<List<List<CellValue>>> toExcelRows(
      {List<FirestoreItem>? otherItems}) async {
    List<List<CellValue>> rows = [];
    List<CellValue> baseItems = [
      TextCellValue(name),
      TextCellValue(description ?? ""),
      TextCellValue(responsible ?? ""),
      IntCellValue(year ?? 1900),
      TextCellValue(type),
      last_modified != null
          ? DateTimeCellValue.fromDateTime(last_modified!)
          : TextCellValue(""),
      DateCellValue(
          year: created?.year ?? 1900,
          month: created?.month ?? 1,
          day: created?.day ?? 1),
    ];

    if (hasNests()) {
      for (String nest in nests!) {
        List<CellValue> items = List.from(baseItems);
        items.add(TextCellValue(nest));
        rows.add(items);
      }
    }
    if (hasBirds()) {
      for (String bird in birds!) {
        List<CellValue> items = List.from(baseItems);
        items.add(TextCellValue(bird));
        rows.add(items);
      }
    }

    if (!hasNests() && !hasBirds()) {
      rows.add(baseItems);
    }
    return rows;
  }
}

Experiment experimentFromSimpleJson(Map<String, dynamic> json) {
  Experiment e = Experiment(
      id: json['id'],
      name: json['name'],
      measures: (json['measures'] as List<dynamic>?)
              ?.map((e) => Measure.fromFormJson(e))
              .toList() ??
          [],
      color: Color(int.parse(json['color'])));
  return e;
}

Container listExperiments(ExperimentedItem item,
    {void Function(Experiment)? onRemove, bool showRemoveHint = false}) {
  if (!item.hasExperiments) {
    return Container();
  }

  List<Widget> experimentButtons = item.experiments?.map((e) {
        Widget button = ElevatedButton(
          key: Key("experimentTag_${e.id ?? e.name}"),
          onPressed: () => null,
          onLongPress: onRemove == null ? null : () => onRemove(e),
          child: Text(e.name),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(e.color),
          ),
        );
        return button;
      }).toList() ??
      [];

  Widget row = Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Text("Exp. "),
      ...experimentButtons,
      //add experiment button
    ],
  );

  return Container(
    padding: EdgeInsets.all(8.0),
    child: showRemoveHint
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row,
              SizedBox(height: 4),
              Text("(long press experiment to remove)",
                  style: TextStyle(fontSize: 10)),
            ],
          )
        : row,
  );
}
