import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/firestore_item.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class Experiment {
  String? id;
  String name = "New Experiment";
  String? description;
  String? responsible;
  Color color = Colors.blue;
  int? year = DateTime.now().year;
  List<String>? nests = [];
  DateTime? last_modified;
  DateTime? created = DateTime.now();

  Experiment(
      {this.id,
      required this.name,
      this.description,
      this.responsible,
      this.year,
      this.nests,
      this.color = Colors.blue,
      this.last_modified,
      this.created});

  Experiment.fromQuerySnapshot(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    id = snapshot.id;
    name = json['name'] ?? "New Experiment";
    description = json['description'];
    responsible = json['responsible'];
    year = json['year'];
    nests = json['nests'];
    color = Color(int.parse(json['color']));
    last_modified = (json['last_modified'] as Timestamp).toDate();
    created = (json['created'] as Timestamp).toDate();
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
      'color': color.value.toString(),
      'last_modified': last_modified,
      'created': created
    };
  }

  Form getExperimentForm(BuildContext context, String person) {
    return Form(
      child: Column(
        children: [
          TextFormField(
            initialValue: name,
            decoration: InputDecoration(labelText: "Name"),
            onChanged: (String? value) => name = value!,
          ),
          TextFormField(
            initialValue: description,
            decoration: InputDecoration(labelText: "Description"),
            onChanged: (String? value) => description = value!,
          ),
          TextFormField(
            initialValue: year.toString(),
            decoration: InputDecoration(labelText: "Year"),
            onChanged: (String? value) => year = int.parse(value!),
          ),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Pick a color!'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: color,
                        onColorChanged: (Color value) => color = value,
                        pickerAreaHeightPercent: 0.8,
                      ),
                    ),
                    actions: <Widget>[
                      ElevatedButton(
                        child: const Text('Got it'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Text("Pick Color"),
          ),
          ElevatedButton(
            onPressed: () async {
              CollectionReference expCollection =
                  FirebaseFirestore.instance.collection('experiments');
              responsible = person;
              last_modified = DateTime.now();
              if (id == null) {
                created = DateTime.now();
                expCollection.add(toJson()).then((value) => {
                      id = value.id,
                      expCollection
                          .doc(id)
                          .collection("changelog")
                          .doc(last_modified.toString())
                          .set(toJson())
                    });
              } else {
                expCollection.doc(id).set(toJson()).then((value) =>
                    expCollection
                        .doc(id)
                        .collection("changelog")
                        .doc(last_modified.toString())
                        .set(toJson()));
              }
              Navigator.pop(context, this);
            },
            child: Text("Save"),
          )
        ],
      ),
    );
  }

  ListTile getListTile(BuildContext context, String person) {
    return ListTile(
      title: Text(name),
      subtitle: Text(description ?? ""),
      trailing: IconButton(
        icon: Icon(Icons.edit, color: Colors.blue),
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return getExperimentForm(context, person);
            },
          );
        },
      ),
    );
  }
  void showNestMap(BuildContext context){
    Navigator.pushNamed(context, "/map", arguments: {'experiment': this});
  }
}



Experiment experimentFromJson(Map<String, dynamic> json) {
  return Experiment(
      id: json['id'],
      name: json['name'],
      color: Color(int.parse(json['color'])));
}

Widget listExperiments(FirestoreItem item) {
  if(item.experiments == null){
    return Container();
  }
  if(item.experiments!.isEmpty){
    return Container();
  }
  return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("Exp. "),
          ...?item.experiments?.map((e) => ElevatedButton(
                onPressed: null,
                child: Text(e.name),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(e.color),
                ),
              )),
        ],
      ));
}
