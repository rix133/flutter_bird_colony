import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/design/speciesRawAutocomplete.dart';
import 'package:kakrarahu/models/firestore/bird.dart';
import 'package:kakrarahu/models/firestore/experiment.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/models/firestore/nest.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:kakrarahu/design/modifingButtons.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;


import 'package:kakrarahu/models/firestore/egg.dart';
import 'package:kakrarahu/models/firestore/species.dart';

class EditBird extends StatefulWidget {
  final FirebaseFirestore firestore;
  const EditBird({Key? key, required this.firestore})  : super(key: key);

  @override
  State<EditBird> createState() => _EditBirdState();
}

class _EditBirdState extends State<EditBird> {
  TextEditingController band_letCntr = TextEditingController();
  TextEditingController band_numCntr = TextEditingController();
  SharedPreferencesService? sps;
  Species _species = Species.empty();
  LocalSpeciesList _speciesList = LocalSpeciesList();
  String _recentMetalBand = "";
  bool buttonsDisabled = false;
  FocusNode _lettersFocus = FocusNode();
  String? previousRouteName;


  Measure color_band = Measure(
    name: "color ring",
    value: "",
    type: "bird",
    isNumber: false,
    unit: "",
    modified: DateTime.now(),
  );


  Measure nestnr = Measure(
    name: "nest",
    type: "bird",
    value: "",
    isNumber: true,
    unit: DateTime.now().year.toString(),
    modified: DateTime.now(),
  );

  Egg? egg;

  String ageType = "any";

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

  CollectionReference? nests;
  CollectionReference? birds;

 @override
 dispose() {
   band_letCntr.dispose();
   band_numCntr.dispose();
   _lettersFocus.dispose();
   bird.dispose();
   super.dispose();
 }

  @override
  void initState() {
    super.initState();
    nests =   widget.firestore.collection(DateTime.now().year.toString());
    birds = widget.firestore.collection("Birds");
    _lettersFocus.addListener(() {
      if (!_lettersFocus.hasFocus) {
        band_letCntr.text = band_letCntr.text.toUpperCase();
        bird.band = (band_letCntr.text + band_numCntr.text).toUpperCase();
        setState(() {  });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      initializeServices();
      var map = ModalRoute.of(context)?.settings.arguments;
      List<Measure> allMeasures = sps?.defaultMeasures ?? [];
      if (map != null) {
        map = map as Map<String, dynamic>;
        await handleMap(map, allMeasures);
      } else {
        handleNoMap(allMeasures);
      }
      autoAssignNextMetalBand(_recentMetalBand);
      setState(() {});
    });
  }

  void initializeServices() {
    sps = Provider.of<SharedPreferencesService>(context, listen: false);
    _speciesList = sps?.speciesList ?? LocalSpeciesList();
  }

  Future<void> handleMap(Map<String, dynamic> map, List<Measure> allMeasures) async {
   if (map["route"] != null) {
      previousRouteName = map["route"];
    }
    if (map["nest"] != null) {
      nest = map["nest"] as Nest;
    }
    if (map["bird"] != null) {
      //ageType is set within handleBird
      await handleBird(map, allMeasures);
    } else if (map["egg"] != null) {
      ageType = "chick";
      handleEgg(map);
    } else {
      //only nest this means ita a prent
      ageType = "parent";
      handleNoBirdNoEgg(allMeasures);
    }
    bird.measures.sort();
    _species = _speciesList.getSpecies(bird.species);
   _recentMetalBand = sps?.getRecentMetalBand(bird.species ?? "") ?? "";
    nestnr.setValue(bird.nest);
    color_band.setValue(bird.color_band);
  }

  Future<void> handleBird(Map<String, dynamic> map, List<Measure> allMeasures) async {
    bird = map["bird"] as Bird;
    if (bird.band.isNotEmpty) {
      await reloadBirdFromFirestore();
    } else {
      if (map["nest"] != null) {
        if(bird.color_band?.isNotEmpty ?? false){
          ageType = "parent";

        }
        updateBirdWithNestInfo();
      } else {
        if (bird.nest_year != DateTime.now().year) {
          bird.nest = "";
        }
      }
    }
    addMissingMeasuresToBird(allMeasures);
  }

  Future<void> reloadBirdFromFirestore() async {
   if(birds == null) return;
    bird = await birds!.doc(bird.band).get().then(
            (DocumentSnapshot value) => Bird.fromDocSnapshot(value)).catchError(onSnapshotError);
    ageType = bird.isChick() ? "chick" : "parent";
    bird.addNonExistingExperiments(nest.experiments, ageType);
  }

  Bird onSnapshotError(error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Error getting bird from firestore: $error"),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 5),
    ));
    return Bird(
      species: nest.species,
      ringed_date: DateTime.now(),
      ringed_as_chick: false,
      band: "",
      responsible: sps?.userName ?? "unknown",
      nest: nest.name,
      nest_year: nest.discover_date.year,
      measures: [Measure.note()],
      experiments: nest.experiments,
    );
  }

  void updateBirdWithNestInfo() {
    bird.nest = nest.name;
    bird.nest_year = nest.discover_date.year;
    bird.species = nest.species;
  }

  void addMissingMeasuresToBird(List<Measure> allMeasures) {
   //filter for bird type measures
    bird.addMissingMeasures(allMeasures, ageType);
  }

  void handleEgg(Map<String, dynamic> map) {
    egg = map["egg"] as Egg;
    bird = Bird(
      species: nest.species,
      ringed_date: DateTime.now(),
      ringed_as_chick: true,
      egg: egg?.getNr(),
      band: "",
      responsible: sps?.userName ?? "unknown",
      nest: nest.name,
      nest_year: nest.discover_date.year,
      measures: [Measure.note()],
      experiments: nest.experiments,
    );
  }

  void handleNoBirdNoEgg(List<Measure> allMeasures) {
    bird = Bird(
      species: nest.species,
      ringed_date: DateTime.now(),
      ringed_as_chick: false,
      band: "",
      responsible: sps?.userName ?? "unknown",
      nest: nest.name,
      nest_year: nest.discover_date.year,
      measures: allMeasures,
      experiments: nest.experiments,
    );
  }

  void handleNoMap(List<Measure> allMeasures) {
    bird.measures = allMeasures;
    if (bird.ringed_as_chick) {
      bird.measures.removeWhere((element) => element.name == "age");
    }
    bird.measures.sort();
  }


  Row metalBand() {
   List<String> recentBand = guessNextMetalBand(_recentMetalBand);
    if(bird.id != null){
      //give unmodifiable row with the band if the bird is from firestore
      int lastLetter = bird.band.lastIndexOf(RegExp(r'[A-Z]'));
      band_letCntr.text = bird.band.substring(0, lastLetter + 1);
      band_numCntr.text = bird.band.substring(lastLetter + 1);
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
          children: [Expanded(child: Padding(padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
              child:Text("Metal: " + bird.band, style: TextStyle(fontSize: 20, color: Colors.yellow))))]);
    }

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
            key: Key("band_letCntr"),
            controller: band_letCntr,
            textAlign: TextAlign.center,
            focusNode: _lettersFocus,
            onChanged: (String value) {
              //check if on web and ios
              if (!Platform.isIOS) {
                band_letCntr.text = band_letCntr.text.toUpperCase();
              }
              bird.band = (band_letCntr.text + band_numCntr.text).toUpperCase();
            },
            onEditingComplete: () {
              band_letCntr.text = band_letCntr.text.toUpperCase();
              bird.band = (band_letCntr.text + band_numCntr.text).toUpperCase();
              setState(() {
                //close the keyboard
                FocusScope.of(context).unfocus();
              });
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
            key: Key("band_numCntr"),
            keyboardType: TextInputType.number,
            controller: band_numCntr,
            onChanged: (String value) {
              bird.band = (band_letCntr.text + band_numCntr.text).toUpperCase();
            },
            onEditingComplete: () {
              band_letCntr.text = band_letCntr.text.toUpperCase();
              bird.band = (band_letCntr.text + band_numCntr.text).toUpperCase();
              setState(() {
                FocusScope.of(context).unfocus();
              });
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
        //add button to assign next metal band
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: _recentMetalBand.isNotEmpty ? () {
            setState(() {
              assignNextMetalBand(_recentMetalBand);
            });
          } : null,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 1.0, vertical: 16.0),
            child:  _recentMetalBand.isNotEmpty ? Text(recentBand.join()) : Text("?????"),
          ),
        ),
      ],
    );
  }

  void addMeasure(Measure m) {
    setState(() {
      bird.measures.add(m);
      bird.measures.sort();
    });
  }

  void saveOk() {
    sps?.setRecentBand(bird.species ?? '', bird.band);
    if(previousRouteName == '/editNest' && ageType == "parent"){
      Navigator.pushNamedAndRemoveUntil(context, '/editNest', ModalRoute.withName('/findNest'), arguments: {"nest_id": nest.name});
    } else {
      Navigator.pop(context);
    }
  }

  void deleteOk() {
   if(previousRouteName == '/editNest' && ageType == "parent"){
      //update the nest manage page
     Navigator.pushNamedAndRemoveUntil(context, '/editNest', ModalRoute.withName('/findNest'), arguments: {"nest_id": nest.name});

    }  else {
     Navigator.pop(context);
   }
  }

  Padding getAgeRow() {
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

  Bird getBird() {
    bird.nest = nestnr.valueCntr.text;
    bird.color_band = color_band.valueCntr.text.toUpperCase();
    return bird;
  }

 List<String> guessNextMetalBand(String recentBand) {
   String letters = "";
   String numbers = "";
   if (recentBand.isNotEmpty) {
     int lastLetter = recentBand.lastIndexOf(RegExp(r'[A-Z]'));
     if (lastLetter != -1) {
       letters = recentBand.substring(0, lastLetter + 1);
       int? nr = int.tryParse(recentBand.substring(lastLetter + 1));
       numbers = nr != null ? (nr + 1).toString() : "";
     } else {
       letters = '';
       int? nr = int.tryParse(recentBand.substring(lastLetter + 1));
       numbers = nr != null ? (nr + 1).toString() : "";
     }
     return [letters, numbers];
   } else{
     return [letters, numbers];
   }
  }



  assignNextMetalBand(String recentBand) {
   List<String> nextBand = guessNextMetalBand(recentBand);
    if (recentBand.isNotEmpty) {
      band_letCntr.text = nextBand[0];
      band_numCntr.text =nextBand[1];
      bird.band = (band_letCntr.text + band_numCntr.text).toUpperCase();
    }
  }

  autoAssignNextMetalBand(String recentBand) {
    if ((ageType == "chick" && (sps?.autoNextBand ?? false)) ||
        (ageType == "parent" && (sps?.autoNextBandParent ?? false))) {
      assignNextMetalBand(recentBand);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Align(
          alignment: Alignment.topCenter,
          child: Container(
              padding: EdgeInsets.fromLTRB(10, 50, 10, 15),
              child: SingleChildScrollView(
                child: Column(children: [
                  Text("Edit bird",
                      style: TextStyle(fontSize: 30, color: Colors.yellow)),
                  SizedBox(height: 10),
                  listExperiments(bird),
                  SpeciesRawAutocomplete(species: _species, returnFun: (Species sp) {
                    setState(() {
                      _species = sp;
                      bird.species = sp.english;
                      _recentMetalBand = sps?.getRecentMetalBand(sp.english) ?? "";
                      autoAssignNextMetalBand(_recentMetalBand);
                    });
                  }, speciesList: sps?.speciesList ?? LocalSpeciesList()),
                  metalBand(),
                  bird.isChick() ? Container() : SizedBox(height: 10),
                  bird.isChick() ? Container() : color_band.getSimpleMeasureForm(),
                  ModifyingButtons(firestore: widget.firestore, context:context,setState:setState, getItem:getBird, type:ageType, otherItems:nests,
                      silentOverwrite: (ageType == "parent"),
                      onSaveOK: saveOk, onDeleteOK: deleteOk),
                  SizedBox(height: 10),
                  nestnr.getSimpleMeasureForm(),
                  //show age in years if ringed as chick
                  bird.ringed_as_chick ? getAgeRow() : Container(),
                  ...bird.measures
                      .map((Measure m) => bird.band.isNotEmpty
                          ? m.getMeasureForm(addMeasure, sps?.biasedRepeatedMeasures ?? false)
                          : Container())
                      .toList(),
                ]),
              )),
        ),
      ),
    );
  }
}
