
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/design/modifingButtons.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

import '../../models/firestore/egg.dart';
import '../../models/measure.dart';

class EditEgg extends StatefulWidget {
  final FirebaseFirestore firestore;
  const EditEgg({Key? key, required this.firestore})  : super(key: key);

  @override
  State<EditEgg> createState() => _EditEggState();
}

class _EditEggState extends State<EditEgg> {
  late Egg egg;
  SharedPreferencesService? sps;
  bool isInit = false;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      var data = ModalRoute.of(context)?.settings.arguments;
      if (data != null) {
        egg = data as Egg;
      } else {
        egg = Egg(
            discover_date: DateTime.now(),
            last_modified: DateTime.now(),
            responsible: sps!.userName,
            measures: [],
            status: "New");
      }
      egg.addMissingMeasures(sps?.defaultMeasures, "egg");
      setState(() {
        isInit = true;
      });
    });
  }

  @override
  dispose() {
    _focusNode.dispose();
    egg.dispose();
    super.dispose();
  }

  void addMeasure(Measure m) {
    setState(() {
      egg.measures.add(Measure.empty(m));
      egg.measures.sort();
    });
  }


   Egg getEgg() {
    //ensure UI is updated
    return egg;
  }

  RawAutocomplete statusField(){
    TextEditingController egg_status = TextEditingController(text: egg.status);
    return(RawAutocomplete<Object>(
        focusNode: _focusNode,
        onSelected: (selectedString) {
          setState(() {
            egg_status.text = selectedString.toString();
            egg.status = selectedString.toString();
          });

        },
        textEditingController: egg_status,
        fieldViewBuilder: (BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted) {
          return TextFormField(
            onTap: () {
              egg_status.text = "";
            },
            textAlign: TextAlign.center,
            controller: textEditingController,
            decoration: InputDecoration(
              labelText: "status",
              hintText: "enter status",
              fillColor: Colors.orange,
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: (BorderSide(color: Colors.indigo))),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
                borderSide: BorderSide(
                  color: Colors.deepOrange,
                  width: 1.5,
                ),
              ),
            ),
            focusNode: focusNode,
            onFieldSubmitted: (String value) {
              onFieldSubmitted();
              FocusScope.of(context).unfocus();
            },
          );
        },
        optionsBuilder: (TextEditingValue textEditingValue) {
          return [
            "intact",
            "predated",
            "crack",
            "broken",
            "missing",
            "unknown",
            "small hole",
            "medium hole",
            "big hole",
            "destroyed by human",
            "drowned",
            "hatched",
            "dead chick",
            "dead egg"
          ].where((element) {
            print(element
                .toString()
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase())
                .toString());
            return element
                .toString()
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase());
          });
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Scaffold(
            body: ListView.separated(
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(
                      option.toString(),
                      textAlign: TextAlign.center,
                    ),
                    textColor: Colors.black,
                    contentPadding: EdgeInsets.all(0),
                    visualDensity: VisualDensity.comfortable,
                    tileColor: Colors.orange[300],
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
                separatorBuilder: (context, index) => Divider(
                  height: 0,
                ),
                itemCount: options.length),
          );
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isInit
          ?  Container(
                  padding: EdgeInsets.fromLTRB(10, 50, 10, 15),
                  child: SingleChildScrollView(
                      child:Align(
                        alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        Text("Nest: " + (egg.id ?? "New Egg"), style: TextStyle(fontSize: 20)),
                        egg.getAgeRow(),
                        SizedBox(height: 10),
                        statusField(),
                        SizedBox(height: 10),
                        ...egg.measures.map((e) => e.getMeasureForm(addMeasure, sps?.biasedRepeatedMeasures ?? false)).toList(),
                        //...egg.getEggForm(context, sps!.userName, _focusNode,  setState, addMeasure),
                        SizedBox(height: 20),
                        ModifyingButtons(firestore: widget.firestore, context:context,setState:setState, getItem:getEgg, type:"egg", otherItems: null, silentOverwrite: true),
                      ],
                    ),
                  )))
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
