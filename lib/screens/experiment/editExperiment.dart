import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/modifingButtons.dart';
import 'package:flutter_bird_colony/models/dataSearch.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

import '../../models/measure.dart';
import '../listMeasures.dart';

class EditExperiment extends StatefulWidget {
  final FirebaseFirestore firestore;
  const EditExperiment({Key? key, required this.firestore})  : super(key: key);

  @override
  State<EditExperiment> createState() => _EditExperimentState();
}

class _EditExperimentState extends State<EditExperiment> {
  SharedPreferencesService? sps;
  CollectionReference? experiments;
  CollectionReference? nestsCollection;
  CollectionReference? birdsCollection;
  CollectionReference? otherCollection;
  Experiment experiment = Experiment(
    name: "",
    year: DateTime.now().year,
    nests: [],
    type: "nest",
    last_modified: DateTime.now(),
    created: DateTime.now(),
    measures: [],
  );

  @override
  void initState() {
    super.initState();
     experiments = widget.firestore.collection('experiments');
     nestsCollection = widget.firestore.collection(DateTime.now().year.toString());
     birdsCollection = widget.firestore.collection('Birds');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      var map = ModalRoute.of(context)?.settings.arguments;
      if (map != null) {
        experiment = map as Experiment;
      }
      otherCollection = getOtherItems();
      setState(() {  });
    });
  }

  @override
  void dispose() {
    experiment.dispose();
    super.dispose();
  }

  List<DropdownMenuItem> types = [
    DropdownMenuItem(child: Text("Nest",style: TextStyle(color: Colors.deepPurpleAccent)), value: "nest"),
    DropdownMenuItem(child: Text("Bird",style: TextStyle(color: Colors.deepPurpleAccent)), value: "bird"),
    DropdownMenuItem(child: Text("Other", style: TextStyle(color: Colors.deepPurpleAccent)), value: "experiment"),
  ];

  CollectionReference? getOtherItems() {
    if (experiment.type == "nest") {
      nestsCollection = widget.firestore.collection(experiment.year.toString());
      return nestsCollection;
    } else if (experiment.type == "bird") {
      return birdsCollection;
    } else {
      return null;
    }
  }

  Widget selectOtherItems(CollectionReference otherItems){
    return StreamBuilder<QuerySnapshot>(
      stream: otherItems.snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading");
        }
        List<String> items = snapshot.data!.docs.map((doc) => doc.id).toList();
        return ElevatedButton.icon(
          icon: Icon(Icons.search),
          label: Text('Select ${experiment.type}s'),
          onPressed: () async {
            final String? selected = await showSearch(
              context: context,
              delegate: DataSearch(items, experiment.type),
            );
            if (selected != null) {
              if (selected.isNotEmpty) {
                setState(() {
                  if (experiment.type == "nest") {
                    if (experiment.nests == null) experiment.nests = [];
                    experiment.nests!.add(selected);
                  } else if (experiment.type == "bird") {
                    if (experiment.birds == null) experiment.birds = [];
                    experiment.birds!.add(selected);
                  }
                });
              }
            }

          },
        );
      },
    );
  }

  Row getDropdownWithLabel(String title, CollectionReference? otherItems) {
    return Row(
      children: [
        Text(title), // This is the label
        DropdownButton(
          value: experiment.type,
          hint: Text(title), // This is the placeholder
          items: types,
          onChanged: (value) {
            setState(() {
              experiment.type = value.toString();
              otherCollection = getOtherItems();
            });
          },
        ),
      ],
    );
  }
  Experiment getExperiment() {
    experiment.last_modified = DateTime.now();
    otherCollection = getOtherItems();
    return experiment;
  }

  measuresUpdated(List<Measure> measures) {
    setState(() {
      experiment.measures = measures;
    });
  }


  Form getExperimentForm(BuildContext context) {
    experiment.responsible = sps?.userName ?? "";
    CollectionReference? otherItems = getOtherItems();
    return Form(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
          child:Column(
        children: [
          TextFormField(
                key: Key("experimentNameField"),
                initialValue: experiment.name,
                decoration: InputDecoration(labelText: "Name"),
            onChanged: (String? value) => experiment.name = value!,
          ),
          SizedBox(height:5),
          TextFormField(
            initialValue: experiment.description,
            decoration: InputDecoration(labelText: "Description"),
            onChanged: (String? value) => experiment.description = value!,
          ),
          SizedBox(height:15),
          getDropdownWithLabel("Select type: ", otherItems),
          SizedBox(height:15),
          selectOtherItems(otherItems!),
          SizedBox(height:15),
          experiment.getItemsList(context, setState),
          SizedBox(height:15),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                        backgroundColor: Colors.black87,
                        title: const Text('Pick a color!'),
                        content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: experiment.color,
                        onColorChanged: (Color value) => experiment.color = value,
                        pickerAreaHeightPercent: 0.8,
                      ),
                    ),
                    actions: <Widget>[
                      ElevatedButton(
                        child: const Text('Got it'),
                        onPressed: () {
                          setState((){});
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
                child: Padding(
                    child: Text("Pick color"),
                    padding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(experiment.color),
            ),
          ),

        ],
      )),
    );
  }

  Widget build(BuildContext context) {
    bool spsOK = sps != null;
    return Scaffold(
        appBar: AppBar(title: Text("Edit Experiment")),
        body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SingleChildScrollView(child:Column(
              children: [
                spsOK ? getExperimentForm(context) : Container(),
                SizedBox(height:15),
                spsOK ? ListMeasures(measures: experiment.measures,onMeasuresUpdated: measuresUpdated) : Container(),
                SizedBox(height:30),
            spsOK
                ? ModifyingButtons(
                    firestore: widget.firestore,
                    context: context,
                    setState: setState,
                    getItem: getExperiment,
                    type: experiment.type,
                    otherItems: otherCollection)
                : Container(),
          ])),
        ));
  }

}