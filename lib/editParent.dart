
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/bird.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/models/nest.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:kakrarahu/design/modifingButtons.dart';
import 'package:provider/provider.dart';


class EditParent extends StatefulWidget {
  const EditParent({Key? key}) : super(key: key);

  @override
  State<EditParent> createState() => _EditParentState();
}

class _EditParentState extends State<EditParent> {
  TextEditingController band_letCntr = TextEditingController();
  TextEditingController band_numCntr = TextEditingController();
  FocusNode _focusNode = FocusNode();
  bool isButtonClicked = false;
  Bird bird = Bird(
    species: "",
    ringed_date: DateTime.now(),
    band: "",
    nest: "",
    measures: [],
    // Add other fields as necessary
  );

  Nest nest = Nest(
    accuracy: "",
    coordinates: GeoPoint(0, 0),
    discover_date: DateTime.now(),
    last_modified: DateTime.now(),
    responsible: "",
    parents: [],
  );

  Measure age = Measure(
    name: "age",
    value: "",
    isNumber: true,
    unit: "years",
  );
  Measure color_band = Measure(
    name: "color ring",
    value: "",
    isNumber: false,
    unit: "",
  );
  Measure head = Measure(
    name: "head length",
    value: "",
    isNumber: true,
    unit: "mm",
  );
  Measure note = Measure(
    name: "note",
    value: "",
    isNumber: false,
    unit: "text",
  );

  Measure gland = Measure(
    name: "gland",
    value: "",
    isNumber: true,
    unit: "mm",
  );

  CollectionReference nests = FirebaseFirestore.instance.collection(DateTime.now().year.toString());
  CollectionReference birds = FirebaseFirestore.instance.collection("Birds");


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sps = Provider.of<SharedPreferencesService>(context, listen: false);
      var map = ModalRoute.of(context)?.settings.arguments as Map;
      nest = map["nest"] as Nest;
      setState(() {
        bird = Bird(
          species: nest.species,
          ringed_date: DateTime.now(),
          band: "",
          responsible: sps.userName,
          nest: nest.name,
          measures: [color_band, head, note, gland, age],
          // Add other fields as necessary
        );
      });
    });
  }

  Row metalBand() {
    if(bird.band.isNotEmpty){
      band_letCntr.text = bird.band.substring(0, 2);
      band_numCntr.text = bird.band.substring(2);
    }
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: band_letCntr,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: "Letters",
              labelStyle: TextStyle(color: Colors.yellow),
              hintText: "UA",
              fillColor: Colors.orange,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: (BorderSide(
                    color: Colors.indigo
                ))
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
                borderSide: BorderSide(
                  color: Colors.deepOrange,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            keyboardType: TextInputType.number,
            controller: band_numCntr,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: "Numbers",
              labelStyle: TextStyle(color: Colors.yellow),
              hintText: "12325",
              fillColor: Colors.orange,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: (BorderSide(
                    color: Colors.indigo
                ))
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
                borderSide: BorderSide(
                  color: Colors.deepOrange,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Center(
          child: Container(
            padding: EdgeInsets.fromLTRB(10, 50, 10, 15),
            child: Column(
              children: [Text("Edit bird"),
              SizedBox(height: 10),
                metalBand(),
                SizedBox(height: 10),
                ...bird.measures.map((Measure m) => m.getMeasureForm()).toList(),
                //add save button
                ElevatedButton.icon(
                  label: Text("Save"),
                  icon: Icon(
                    Icons.save,
                    color: Colors.black87,
                    size: 45,
                  ),
                  onPressed: isButtonClicked ? null : () async {
                    isButtonClicked = true;
                    bird.band = band_letCntr.text + band_numCntr.text;
                    bird.measures.forEach((element) {
                      element.value = element.valueCntr.text;
                    });
                    bool saveOK = await bird.save2Firestore(birds, nests, true, false);
                    if (saveOK) {
                      Navigator.pop(context);
                    } else{
                      showDialog(context: context, builder: (_) =>
                          AlertDialog(
                            title: Text("${band_letCntr.text + band_numCntr.text} already used! Do you want to overwrite?",
                                style: TextStyle(color: Colors.deepPurpleAccent)
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text("Cancel"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: const Text("Overwrite"),
                                onPressed: () async{
                                  Navigator.of(context).pop();
                                  await bird.save2Firestore(birds, nests, true, true);
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          ));
                    }
                  },
                )
              ]
            ),
          ),
        ),
      ),
    );
  }
}
