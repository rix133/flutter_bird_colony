import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/design/speciesInput.dart';
import 'package:kakrarahu/models/bird.dart';
import 'package:kakrarahu/models/experiment.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/models/nest.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:kakrarahu/design/modifingButtons.dart';
import 'package:provider/provider.dart';

import 'models/egg.dart';

class EditParent extends StatefulWidget {
  const EditParent({Key? key}) : super(key: key);

  @override
  State<EditParent> createState() => _EditParentState();
}

class _EditParentState extends State<EditParent> {
  TextEditingController band_letCntr = TextEditingController();
  TextEditingController band_numCntr = TextEditingController();
  TextEditingController speciesCntr = TextEditingController();
  FocusNode _focusNode = FocusNode();

  Measure age = Measure(
    name: "age",
    value: "",
    isNumber: true,
    type: "bird",
    unit: "years",
    modified: DateTime.now(),
  );
  Measure color_band = Measure(
    name: "color ring",
    value: "",
    type: "bird",
    isNumber: false,
    unit: "",
    modified: DateTime.now(),
  );
  Measure head = Measure(
    name: "head length",
    value: "",
    type: "bird",
    isNumber: true,
    unit: "mm",
    modified: DateTime.now(),
  );
  Measure note = Measure(
    name: "note",
    value: "",
    type: "any",
    isNumber: false,
    unit: "text",
    modified: DateTime.now(),
  );

  Measure gland = Measure(
    name: "gland",
    value: "",
    type: "bird",
    isNumber: true,
    unit: "mm",
    modified: DateTime.now(),
  );

  Measure nestnr = Measure(
    name: "nest",
    type:  "bird",
    value: "",
    isNumber: true,
    unit: DateTime.now().year.toString(),
    modified: DateTime.now(),
  );

  Egg? egg;

  String type = "parent";

  Bird bird = Bird(
    species: "",
    ringed_date: DateTime.now(),
    ringed_as_chick: false,
    band: "",
    nest: "",
    nest_year: DateTime.now().year,
    measures: [],
    experiments: [],
    // Add other fields as necessary
  );

  Nest nest = Nest(
    accuracy: "",
    coordinates: GeoPoint(0, 0),
    discover_date: DateTime.now(),
    last_modified: DateTime.now(),
    responsible: "",
    experiments: [],
    measures: [],
  );

  CollectionReference nests =
      FirebaseFirestore.instance.collection(DateTime.now().year.toString());
  CollectionReference birds = FirebaseFirestore.instance.collection("Birds");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
          //does the bird exist in firestore
          if (bird.band.isNotEmpty && (bird.id == null)) {
            //reload from firestore this comes from nest and has firestore instance
            bird = await birds
                .doc(bird.band)
                .get()
                .then((DocumentSnapshot value) =>
                Bird.fromQuerySnapshot(value));
          }else{
            if (map["nest"] != null) {
              bird.nest = nest.name;
              bird.nest_year = nest.discover_date.year;
              bird.species = nest.species;
            } else {
              if(bird.nest_year != DateTime.now().year){
                bird.nest = "";
              }
            }
          }
          //check if measure is missing and add if needed
          if (bird.measures == null) {
            bird.measures = [];
          }
            for (Measure m in allMeasures) {
              if (!bird.measures!.map((e) => e.name).contains(m.name)) {
                bird.measures!.add(m);
              }

          }
        }

        //its hatching time
        else if(map["egg"] != null){
          type ="chick";
          egg = map["egg"] as Egg;
          bird = Bird(
            species: nest.species,
            ringed_date: DateTime.now(),
            ringed_as_chick: true,
            egg: egg?.getNr(),
            band: "",
            responsible: sps.userName,
            nest: nest.name,
            nest_year: nest.discover_date.year,
            measures: allMeasures,
            experiments: nest.experiments,
            // Add other fields as necessary
          );
        }
        else {
          bird = Bird(
            species: nest.species,
            ringed_date: DateTime.now(),
            ringed_as_chick: false,
            band: "",
            responsible: sps.userName,
            nest: nest.name,
            nest_year: nest.discover_date.year,
            measures: allMeasures,
            experiments: nest.experiments,
            // Add other fields as necessary
          );
        }
        bird.measures!.sort();
        speciesCntr.text = bird.species ?? "";
        nestnr.setValue(bird.nest);
        color_band.setValue(bird.color_band);
        setState(() {});
      } else {
        bird.measures = allMeasures;
        //remove age from measures if ringed as chick
        if (bird.ringed_as_chick) {
          bird.measures!.removeWhere((element) => element.name == "age");
        }
        bird.measures!.sort();
        setState(() {});
        return;
      }
    });
  }

  Row metalBand() {
    if (bird.band.isNotEmpty) {
      // take the letters and numbers apart
      // and put them in the textfields
      int lastLetter = bird.band.lastIndexOf(RegExp(r'[A-Z]'));
      if (lastLetter != -1) {
        band_letCntr.text = bird.band.substring(0, lastLetter + 1);
        band_numCntr.text = bird.band.substring(lastLetter + 1);
      } else {
        // handle the case when there are no letters
        band_letCntr.text = '';
        band_numCntr.text = bird.band;
      }
    }
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: band_letCntr,
            textAlign: TextAlign.center,
            onChanged: (String value) {
              bird.band = (band_letCntr.text + band_numCntr.text).toUpperCase();
              setState(() {});
            },
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
            onChanged: (String value) {
              bird.band = (band_letCntr.text + band_numCntr.text).toUpperCase();
              setState(() {});
            },
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

  void addMeasure(Measure m) {
    bird.measures = bird.measures!.map((e) => e..value= e.valueCntr.text).toList();
    setState(() {
      bird.measures!.add(m);
      bird.measures!.sort();
    });
  }

  Padding getAgeRow(){
    int ageYears = DateTime.now().year - bird.ringed_date.year;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Text('Age: $ageYears years',
                style: TextStyle(fontSize: 20, color: Colors.yellow))),
        ],
      ),
    );
  }

  Bird getBird(BuildContext context) {
    //ensure UI is updated
    bird.band = (band_letCntr.text + band_numCntr.text).toUpperCase();
    bird.species = speciesCntr.text;
    checkNestChange(nestnr.valueCntr.text, nest.discover_date.year);
    bird.nest = nestnr.valueCntr.text;
    bird.color_band = color_band.valueCntr.text.toUpperCase();
    return bird;
  }

  Future<bool> checkNestChange(String newNestName, int nestYear) async {
    //its from another year the nest number
    if (nestYear != DateTime.now().year) {
      return false;
    }
    // the nest is from this year and is updated to something
    if (newNestName != bird.nest && (bird.current_nest).isNotEmpty) {
      return (await nests
          .doc(bird.current_nest)
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
              child: SingleChildScrollView(
                child: Column(children: [
                  Text("Edit bird",
                      style: TextStyle(fontSize: 30, color: Colors.yellow)),
                  SizedBox(height: 10),
                  listExperiments(bird),
                  buildRawAutocomplete(speciesCntr, _focusNode),
                  nestnr.getMeasureForm(),
                  metalBand(),
                  SizedBox(height: 10),
                  color_band.getMeasureForm(),
                  listExperiments(bird),
                  modifingButtons(context, getBird, type, nests, {"sihtkoht":bird.nest}, "/nestManage", silentOverwrite: type == "parent"),
                  SizedBox(height: 10),
                  //show age in years if ringed as chick
                  bird.ringed_as_chick ? getAgeRow() : Container(),
                  ...?bird.measures
                      ?.map((Measure m) => bird.band.isNotEmpty ?
                          m.getMeasureFormWithAddButton(addMeasure) : Container())
                      .toList(),
                ]),
              )),
        ),
      ),
    );
  }
}
