import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/experiment.dart';
import 'package:kakrarahu/models/firestore_item.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';
import 'package:kakrarahu/models/dataSearch.dart';
import 'package:kakrarahu/design/modifingButtons.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class EditExperiment extends StatefulWidget {
  const EditExperiment({Key? key}) : super(key: key);

  @override
  State<EditExperiment> createState() => _EditExperimentState();
}

class _EditExperimentState extends State<EditExperiment> {
  SharedPreferencesService? sps;
  CollectionReference experiments = FirebaseFirestore.instance.collection('experiments');
  Experiment experiment = Experiment(
    name: "",
    year: DateTime.now().year,
    nests: [],
    type: "nest",
    last_modified: DateTime.now(),
    created: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      var map = ModalRoute.of(context)?.settings.arguments;
      if (map != null) {
        map = map as Map<String, dynamic>;
        if (map["experiment"] != null) {
          experiment = map["experiment"] as Experiment;
        }
      }
      setState(() {  });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<DropdownMenuItem> types = [
    DropdownMenuItem(child: Text("Nest",style: TextStyle(color: Colors.deepPurpleAccent)), value: "nest"),
    DropdownMenuItem(child: Text("Bird",style: TextStyle(color: Colors.deepPurpleAccent)), value: "bird"),
    DropdownMenuItem(child: Text("Other", style: TextStyle(color: Colors.deepPurpleAccent)), value: "experiment"),
  ];

  CollectionReference? getOtherItems(String type) {
    if (type == "nest") {
      return FirebaseFirestore.instance.collection(DateTime
          .now()
          .year
          .toString());
    } else if (type == "bird") {
      return FirebaseFirestore.instance.collection("Birds");
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
        return IconButton(
          icon: Icon(Icons.search),
          onPressed: () async {
            final String? selected = await showSearch(
              context: context,
              delegate: DataSearch(items),
            );
            if (selected != null) {
              if(experiment.type == "nest"){
                experiment.nests!.add(selected);
              } else if(experiment.type == "bird"){
                experiment.birds!.add(selected);
              }
            }
          },
        );
      },
    );
  }


  Row getDropdownWithLabel(CollectionReference? otherItems) {
    return Row(
      children: [
        Text('Select Type: '), // This is the label
        DropdownButton(
          value: experiment.type,
          hint: Text('Select Type'), // This is the placeholder
          items: types,
          onChanged: (value) {
            setState(() {
              experiment.type = value.toString();
              otherItems = getOtherItems(experiment.type);
            });
          },
        ),
      ],
    );
  }
  Experiment getExperiment() {
    experiment.last_modified = DateTime.now();
    return experiment;
  }


  Form getExperimentForm(BuildContext context) {
    experiment.responsible = sps?.userName ?? "";
    CollectionReference? otherItems = getOtherItems(experiment.type);
    return Form(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
          child:Column(
        children: [
          TextFormField(
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
          TextFormField(
            initialValue: experiment.year.toString(),
            decoration: InputDecoration(labelText: "Year"),
            onChanged: (String? value) => experiment.year = int.parse(value!),
          ),
          SizedBox(height:15),
          getDropdownWithLabel(otherItems),
          SizedBox(height:15),
          selectOtherItems(otherItems!),
          SizedBox(height:15),
          experiment.getItemsRow(context),
          SizedBox(height:15),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
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
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Text("Pick Color"),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(experiment.color),
            ),
          ),
          SizedBox(height:15),
          modifingButtons(context, getExperiment, experiment.type, otherItems, null,null),

        ],
      )),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Edit Experiment", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.redAccent,
        ),
        body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SingleChildScrollView(child:Column(
              children: [
                sps != null ? getExperimentForm(context) : Container(),
              ])),
            ));
  }

}