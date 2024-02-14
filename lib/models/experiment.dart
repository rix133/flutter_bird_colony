import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/design/modifingButtons.dart';
import 'package:kakrarahu/models/experimented_item.dart';
import 'package:kakrarahu/models/firestore_item.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kakrarahu/models/updateResult.dart';

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
  String type = "nest";
  DateTime? last_modified;
  DateTime? created = DateTime.now();

  List<String> previousOtherItems = [];

  Experiment({this.id,
    required this.name,
    this.description,
    this.responsible,
    this.year,
    this.nests,
    this.type = "nest",
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
    nests = List<String>.from(json['nests'] ?? []);
    birds = List<String>.from(json['birds'] ?? []);
    type = json['type'] ?? "nest";
    color = Color(int.parse(json['color']));
    last_modified = (json['last_modified'] as Timestamp).toDate();
    created = (json['created'] as Timestamp).toDate();
    if(type=="nest"){
      previousOtherItems = nests ?? [];
    } else if(type=="bird"){
      previousOtherItems = birds ?? [];
    }
  }

  Map<String, dynamic> toSimpleJson() {
    return {'id': id, 'name': name, 'color': color.value.toString()};
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


  @override
  Future<UpdateResult> delete({CollectionReference<
      Object?>? otherItems = null, bool soft = true, String type = "default"}) {
    CollectionReference expCollection =   FirebaseFirestore.instance.collection('experiments');
    if(otherItems != null){
      List <String> otherData = [];
      if(type == "nest"){
        otherData = nests!;
      } else if(type == "bird"){
        otherData = birds!;
      }
      List<Experiment> presentExperiments = [];
        otherData.forEach((element) {
          otherItems!.doc(element).get().then((value) => {
            if(value.exists){
              presentExperiments = value["experiments"].map((e) => e.experimentFromJson(e)).toList(),
              presentExperiments.removeWhere((element) => element.id == id),
              otherItems!.doc(element).update({"experiments": presentExperiments.map((e) => e.toSimpleJson()).toList()})
            }
          });
        });

    }

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

      //check if the item is already in deleted collection
      return deletedCollection.doc(id).get().then((doc) {
        if (doc.exists == false) {
          return deletedCollection
              .doc(id)
              .set(toJson())
              .then((value) => expCollection.doc(id).delete().then((value) => UpdateResult.deleteOK(item: this)))
              .catchError((error) => UpdateResult.error(message: error.toString()));
        } else {
          return deletedCollection
              .doc('${id}_${DateTime.now().toString()}')
              .set(toJson())
              .then((value) => expCollection.doc(id).delete().then((value) => UpdateResult.deleteOK(item: this)))
              .catchError((error) => UpdateResult.error(message: error.toString()));
        }
      }).catchError((error) => UpdateResult.error(message: error.toString()));
    }
  }

  @override
  Future<UpdateResult> save({CollectionReference<
      Object?>? otherItems = null, bool allowOverwrite = false, String type = "default"}) {
    CollectionReference expCollection =   FirebaseFirestore.instance.collection('experiments');
    last_modified = DateTime.now();
    //remove duplicate nests
    if(nests != null){
      nests = nests!.toSet().toList();
    }
    if(birds != null){
      birds = birds!.toSet().toList();
    }
    List <String> otherData = [];
    List<dynamic> presentExperiments = [];
    //get items that are missing from otherdata but exist in previousOtherItems
    List<String> deletedItems = previousOtherItems.where((element) => !otherData.contains(element)).toList();
    if(otherItems != null){
      if(type == "nest"){
        otherData = nests!;
      } else if(type == "bird"){
        otherData = birds!;
      }
    }

    if (id == null) {
      created = DateTime.now();
      id = created!.toIso8601String();
    }
      return(expCollection.doc(id).set(toJson()).then((value) =>
      {
        if(otherItems != null){
          //save the experiment data to nests or birds
        for(String d in otherData){
          otherItems!.doc(d).get().then((DocumentSnapshot value) => {
            if(value.exists){
              presentExperiments = value.get("experiments")?.map((e) => experimentFromJson(e)).toList() ?? [],
              //check if the experiment is already in the list by id
              if(!presentExperiments.any((element) => element.id == id)){
                presentExperiments.add(this),
                otherItems!.doc(d).update({"experiments": presentExperiments.map((e) => e.toSimpleJson()).toList()})
              } else {
                //update the experiment in the list
                presentExperiments[presentExperiments.indexWhere((element) => element.id == id)] = this,
                otherItems!.doc(d).update({"experiments": presentExperiments.map((e) => e.toSimpleJson()).toList()})
              }
            }
          }
          )},
        //remove the deleted items from the nests or birds
        for(String d in deletedItems){
          otherItems!.doc(d).get().then((DocumentSnapshot value) => {
            if(value.exists){
              presentExperiments = value.get("experiments")?.map((e) => e.experimentFromJson(e)).toList() ?? [],
              presentExperiments.removeWhere((element) => element.id == id),
              otherItems!.doc(d).update({"experiments": presentExperiments.map((e) => e.toSimpleJson()).toList()})
            }
          }),
        }
        },
        expCollection
            .doc(id)
            .collection("changelog")
            .doc(last_modified.toString())
            .set(toJson())
      }).then((value) => UpdateResult.saveOK(item:this))).catchError((onError) => UpdateResult.error(message: onError.toString()));

    }

}

Experiment experimentFromJson(Map<String, dynamic> json) {
  return Experiment(
      id: json['id'],
      name: json['name'],
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
                onPressed: null,
                child: Text(e.name),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(e.color),
                ),
              )),
        ],
      ));
}
