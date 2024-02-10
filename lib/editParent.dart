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

  Measure nestnr = Measure(
    name: "nest",
    value: "",
    isNumber: true,
    unit: "",
  );
  Measure species = Measure(
    name: "species",
    value: "Common Gull",
    isNumber: false,
    unit: "",
  );

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

  CollectionReference nests =
      FirebaseFirestore.instance.collection(DateTime.now().year.toString());
  CollectionReference birds = FirebaseFirestore.instance.collection("Birds");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sps = Provider.of<SharedPreferencesService>(context, listen: false);
      var map = ModalRoute.of(context)?.settings.arguments;
      List<Measure> allMeasures = [note, head, gland, age];
      if (map != null) {
        map = map as Map<String, dynamic>;
        if (map["nest"] != null) {
          nest = map["nest"] as Nest;
        }
        if (map["bird"] != null) {
          bird = map["bird"] as Bird;
          //check if measure is missing and add if needed
          for (Measure m in allMeasures) {
            if (!bird.measures.map((e) => e.name).contains(m.name)) {
              bird.measures.add(m);
            }
          }
        } else {
          bird = Bird(
            species: nest.species,
            ringed_date: DateTime.now(),
            band: "",
            responsible: sps.userName,
            nest: nest.name,
            measures: allMeasures,
            // Add other fields as necessary
          );
          nestnr.value = nest.name;
          species.value = nest.species ?? "Common Gull";
        }
        setState(() {});
      } else {
        bird.measures = allMeasures;
        setState(() {});
        return;
      }
    });
  }

  Row metalBand() {
    if (bird.band.isNotEmpty) {
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
                  borderSide: (BorderSide(color: Colors.indigo))),
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
                  borderSide: (BorderSide(color: Colors.indigo))),
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

  Bird getBird() {
    //ensure UI is updated
    bird.band = (band_letCntr.text + band_numCntr.text).toUpperCase();
    bird.species = species.valueCntr.text;
    checkNestChange(nestnr.valueCntr.text);
    bird.nest = nestnr.valueCntr.text;
    bird.color_band = color_band.valueCntr.text.toUpperCase();
    bird.measures.forEach((element) {
      element.value = element.valueCntr.text;
    });
    return bird;
  }

  Future<bool> checkNestChange(String newNestName) async {
    if (newNestName != bird.nest && (bird.nest ?? "").isNotEmpty) {
      return (await nests
          .doc(bird.nest)
          .collection("parents")
          .doc(bird.band)
          .delete()
          .then((value) => true)
          .catchError((error) => false));
    }
    return false;
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
            child: Column(children: [
              Text("Edit bird",
                  style: TextStyle(fontSize: 30, color: Colors.yellow)),
              SizedBox(height: 10),
              species.getMeasureForm(),
              nestnr.getMeasureForm(),
              metalBand(),
              SizedBox(height: 10),
              color_band.getMeasureForm(),
              ...bird.measures.map((Measure m) => m.getMeasureForm()).toList(),
              modifingButtons(context, getBird, "parent",
                  nests.doc(nest.name).collection("parents")),
            ]),
          ),
        ),
      ),
    );
  }
}
