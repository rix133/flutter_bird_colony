import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/design/modifingButtons.dart';
import 'package:kakrarahu/models/experimented_item.dart';
import 'package:kakrarahu/models/firestore_item.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/models/updateResult.dart';
import 'package:kakrarahu/services/deleteService.dart';

import 'bird.dart';
import 'nest.dart';

class Experiment implements FirestoreItem {
  String? id;
  String name = "New Experiment";
  String? description;
  String? responsible;
  Color color = Colors.grey;
  int? year = DateTime
      .now()
      .year;
  List<String>? nests = [];
  List<String>? birds = [];
  List<Measure> measures = [];
  String type = "nest";
  DateTime? last_modified;
  DateTime? created = DateTime.now();

  List<String> previousNests = [];
  List<String> previousBirds = [];

  Experiment({this.id,
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

  Experiment.fromQuerySnapshot(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    id = snapshot.id;
    name = json['name'] ?? "Untitled experiment";
    description = json['description'];
    responsible = json['responsible'];
    year = json['year'];
    measures = (json['measures'] as List<dynamic>?)
        ?.map((e) => measureFromJson(e))
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
    return {'id': id, 'name': name, 'color': color.value.toString(), 'measures': measures?.map((e) => e.toFormJson()).toList()};
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
      'color': color.value.toString(),
      'last_modified': last_modified,
      'measures': measures?.map((e) => e.toJson()).toList(),
      'created': created
    };
  }

  bool hasNests(){
    if(nests != null){
      if(nests!.isNotEmpty){
        return true;
      }
    }
    return false;
  }

  bool hasBirds(){
    if(birds != null){
      if(birds!.isNotEmpty){
        return true;
      }
    }
    return false;
  }

  Column getItemsList(BuildContext context, Function setState) {
    List<Padding> items = [];
    if(hasNests()){
      items.addAll(nests?.map((e) => Padding(padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),  child: Container(
        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(5)),
          child:ListTile(
        title: Text(e),
        onTap: gotoNest(e, context),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () {
            setState(() {
            nests!.remove(e);
            });
          },
        ),
      )))).toList() ?? []);
    }
    if(hasBirds()){
      items.addAll(birds?.map((e) => Padding(padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),  child: Container(
        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(5)),
          child:ListTile(
        title: Text(e),
        onTap: gotoBird(e, context),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () {
            setState(() {
            birds!.remove(e);
            });
          },
        ),
      )))).toList() ?? []);
    }
    return Column(
      children: items,
    );
  }


  gotoNest(String nest, BuildContext context){
    return () => {
      Navigator.pushNamed(context, "/nestManage", arguments: {'sihtkoht': nest})
    };
  }
  gotoBird(String bird, BuildContext context){
    return () => {
      Navigator.pushNamed(context, "/editParent", arguments: {'bird': {'band': bird}})
    };
  }

  String get titleString => '$name${description?.isNotEmpty == true ? ' - $description' : ''}';

  Widget getListTile(BuildContext context, String person) {
    String subtitleNests = hasNests() ? "Nests: " + nests!.join(", ") : "";
    String subtitleBirds = hasBirds() ? "Birds: " + birds!.join(", ") : "";
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      child: Container(
        child: ListTile(
          title: Text(titleString, style: TextStyle(fontSize: 20)),
          subtitle: Text(subtitleNests + subtitleBirds, style: TextStyle(color: Colors.grey, fontSize: 12)),
          onTap: (){
            showNestMap(context);
          },
          trailing: IconButton(
            icon: Icon(Icons.edit, color: Colors.black),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.white60),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/editExperiment', arguments: {'experiment': this});
            },
          ),
        ),
      ),
    );
  }

  void showNestMap(BuildContext context) {
    Navigator.pushNamed(context, "/map", arguments: {'nests': nests});
  }


  Future<UpdateResult> _updateNestCollection(List<String>? items, {bool delete = false}) async {
    CollectionReference nestCollection =  FirebaseFirestore.instance.collection(year.toString());
    if(items != null){
      Nest n;
      for(String i in items){
         await nestCollection.doc(i).get().then((DocumentSnapshot value) => {
          if(value.exists){
            n = Nest.fromQuerySnapshot(value),
            n.experiments = n.experiments?.where((element) => element.id != id).toList(),
            if(!delete){
              n.experiments?.add(this),
            },
            nestCollection.doc(i).update({'experiments': n.experiments?.map((e) => e.toSimpleJson()).toList()})
          }
        });
      }
    }
    return UpdateResult.saveOK(item: this);
  }

  Future<UpdateResult> _updateBirdsCollection(List<String>? items, {bool delete = false}) async {
    CollectionReference birdCollection =  FirebaseFirestore.instance.collection(year.toString());
    if(items != null){
      Bird b;
      for(String i in items){
         await birdCollection.doc(i).get().then((DocumentSnapshot value) => {
          if(value.exists){
            b = Bird.fromQuerySnapshot(value),
            b.experiments = b.experiments?.where((element) => element.id != id).toList(),
            if(!delete){
              b.experiments?.add(this),
            },
            birdCollection.doc(i).update({'experiments': b.experiments?.map((e) => e.toSimpleJson()).toList()})
          }
        });
      }
    }
    return UpdateResult.saveOK(item: this);
  }


  @override
  Future<UpdateResult> delete({CollectionReference<
      Object?>? otherItems = null, bool soft = true, String type = "default"}) {
    CollectionReference expCollection =   FirebaseFirestore.instance.collection('experiments');

    _updateNestCollection(previousNests, delete: true);
    _updateBirdsCollection(previousBirds, delete: true);

    if (!soft) {
      return expCollection
          .doc(id)
          .delete()
          .then((value) => UpdateResult.deleteOK(item: this))
          .catchError((error) => UpdateResult.error(message: error.toString()));
    }  else {
      CollectionReference deletedCollection = FirebaseFirestore.instance
          .collection("deletedItems")
          .doc("experiments")
          .collection("deleted");

      return deleteFiresoreItem(this, expCollection, deletedCollection);
    }
  }

  @override
  Future<UpdateResult> save({CollectionReference<
      Object?>? otherItems = null, bool allowOverwrite = false, String type = "default"}) {
    CollectionReference expCollection =   FirebaseFirestore.instance.collection('experiments');
    print(previousNests);
    print(nests);

    last_modified = DateTime.now();
    //remove duplicate nests
    if(nests != null){
      nests = nests!.toSet().toList();
    }
    if(birds != null){
      birds = birds!.toSet().toList();
    }
    //get items that are missing from otherdata but exist in previousOtherItems
    List<String> deletedNests = previousNests.where((element) => !nests!.contains(element)).toList();
    List<String> deletedBirds = previousBirds.where((element) => !birds!.contains(element)).toList();
    print(deletedNests);

    if (id == null) {
      created = DateTime.now();
      id = created!.toIso8601String();
    }

    //save the experiment data to nests or birds
    _updateNestCollection(nests, delete: false);
    _updateNestCollection(deletedNests, delete: true);
    _updateBirdsCollection(birds, delete: false);
    _updateBirdsCollection(deletedBirds, delete: true);

      return(expCollection.doc(id).set(toJson()).then((value) =>
      {
        expCollection
            .doc(id)
            .collection("changelog")
            .doc(last_modified.toString())
            .set(toJson())
      }).then((value) => UpdateResult.saveOK(item:this))).catchError((onError) => UpdateResult.error(message: onError.toString()));

    }

}

Experiment experimentFromSimpleJson(Map<String, dynamic> json) {
  return Experiment(
      id: json['id'],
      name: json['name'],
      measures: (json['measures'] as List<dynamic>?)
          ?.map((e) => measureFromFormJson(e))
          .toList() ??
          [],
      color: Color(int.parse(json['color'])));
}

Widget listExperiments(ExperimentedItem item) {
  if (item.experiments == null) {
    return Container();
  }
  if (item.experiments!.isEmpty) {
    return Container();
  }
  return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("Exp. "),
          ...?item.experiments?.map((e) =>
              ElevatedButton(
                onPressed: () => null,
                child: Text(e.name),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(e.color),
                ),
              )),
        ],
      ));
}
