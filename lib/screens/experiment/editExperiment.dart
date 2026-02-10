import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/modifingButtons.dart';
import 'package:flutter_bird_colony/models/dataSearch.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_bird_colony/utils/year.dart';
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

class _BulkAddResult {
  final List<String> toAdd;
  final List<String> invalid;

  _BulkAddResult(this.toAdd, this.invalid);
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
     birdsCollection = widget.firestore.collection('Birds');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      var map = ModalRoute.of(context)?.settings.arguments;
      if (map != null) {
        experiment = map as Experiment;
      } else {
        experiment.year = sps?.selectedYear ?? experiment.year;
      }
      nestsCollection = widget.firestore.collection(
          yearToNestCollectionName(experiment.year ?? DateTime.now().year));
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
      nestsCollection = widget.firestore.collection(
          yearToNestCollectionName(experiment.year ?? DateTime.now().year));
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
        return Column(
          children: [
            ElevatedButton.icon(
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
                      _addItemsToExperiment([selected]);
                    });
                  }
                }

              },
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              key: Key("bulkAdd${experiment.type}Button"),
              icon: Icon(Icons.playlist_add),
              label: Text('Bulk add ${experiment.type}s'),
              onPressed: () => _showBulkAddDialog(items),
            ),
          ],
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

  List<String> _parseBulkItems(String raw) {
    return raw
        .split(RegExp(r'[\s,;]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _addItemsToExperiment(List<String> ids) {
    if (experiment.type == "nest") {
      experiment.nests ??= [];
      experiment.nests!.addAll(ids);
      experiment.nests = experiment.nests!.toSet().toList();
    } else if (experiment.type == "bird") {
      experiment.birds ??= [];
      experiment.birds!.addAll(ids);
      experiment.birds = experiment.birds!.toSet().toList();
    }
  }

  Future<void> _showInvalidItemsDialog(List<String> invalid) async {
    if (invalid.isEmpty || !mounted) {
      return;
    }
    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text("Unknown ${experiment.type}s"),
        content: Text(invalid.join(", ")),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          )
        ],
      ),
    );
  }

  Future<void> _showBulkAddDialog(List<String> items) async {
    TextEditingController controller = TextEditingController();
    final result = await showDialog<_BulkAddResult>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Text("Bulk add ${experiment.type}s"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Paste IDs separated by commas, spaces, or new lines."),
              SizedBox(height: 10),
              TextField(
                key: Key("bulkAdd${experiment.type}Field"),
                controller: controller,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: "1, 2, 3",
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              key: Key("confirmBulkAdd${experiment.type}Button"),
              onPressed: () {
                List<String> parsed = _parseBulkItems(controller.text);
                Set<String> itemSet = items.toSet();
                List<String> toAdd = [];
                List<String> invalid = [];
                for (String id in parsed) {
                  if (itemSet.contains(id)) {
                    if (!toAdd.contains(id)) {
                      toAdd.add(id);
                    }
                  } else {
                    invalid.add(id);
                  }
                }
                Navigator.pop(context, _BulkAddResult(toAdd, invalid));
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
    if (result == null) {
      return;
    }
    if (result.toAdd.isNotEmpty) {
      setState(() {
        _addItemsToExperiment(result.toAdd);
      });
    }
    if (result.invalid.isNotEmpty) {
      await _showInvalidItemsDialog(result.invalid);
    }
  }

  Future<void> _copyExperimentDialog() async {
    if (experiment.id == null) {
      return;
    }
    TextEditingController controller =
        TextEditingController(text: "${experiment.name} copy");
    String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text("Copy experiment"),
        content: TextField(
          key: Key("copyExperimentNameField"),
          controller: controller,
          decoration: InputDecoration(labelText: "New name"),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            key: Key("confirmCopyExperimentButton"),
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text("Create copy"),
          ),
        ],
      ),
    );

    newName = newName?.trim();
    if (newName == null || newName.isEmpty || !mounted) {
      return;
    }

    Experiment copied = experiment.copy();
    copied.id = null;
    copied.name = newName;
    copied.created = DateTime.now();
    copied.last_modified = DateTime.now();
    copied.previousBirds = [];
    copied.previousNests = [];
    copied.responsible = sps?.userName ?? copied.responsible;

    final result = await copied.save(widget.firestore, type: copied.type);
    if (!mounted) {
      return;
    }
    if (!result.success) {
      await showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          backgroundColor: Colors.black87,
          title: Text("Copy failed"),
          content: Text(result.message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            )
          ],
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/editExperiment', arguments: copied);
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
                  backgroundColor: WidgetStateProperty.all(experiment.color),
            ),
          ),

        ],
      )),
    );
  }

  Widget build(BuildContext context) {
    bool spsOK = sps != null;
    return Scaffold(
        appBar: (sps?.showAppBar ?? true)
            ? AppBar(
                title: Text('Edit Experiment'),
              )
            : null,
        body: SafeArea(
            child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(child:Column(
              children: [
                spsOK ? getExperimentForm(context) : Container(),
                SizedBox(height:15),
                spsOK ? ListMeasures(measures: experiment.measures,onMeasuresUpdated: measuresUpdated) : Container(),
                SizedBox(height:30),
            spsOK && experiment.id != null
                ? ElevatedButton.icon(
                    key: Key("copyExperimentButton"),
                    onPressed: _copyExperimentDialog,
                    icon: Icon(Icons.content_copy),
                    label: Text("Copy experiment"),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.grey),
                    ),
                  )
                : Container(),
            spsOK && experiment.id != null ? SizedBox(height: 15) : Container(),
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
        )));
  }

}

