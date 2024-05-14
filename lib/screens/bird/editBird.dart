import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/modifingButtons.dart';
import 'package:flutter_bird_colony/design/speciesRawAutocomplete.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/models/firestore/egg.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

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
  bool disableBandChangeButtons = false;
  List<Measure> allMeasures = [Measure.note()];

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

  String ageType = "parent"; //defaults to adult

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
      allMeasures = sps?.defaultMeasures ?? [];
      if (map != null) {
        map = map as Map<String, dynamic>;
        await handleMap(map);
      } else {
        handleNoMap();
      }
      autoAssignNextMetalBand(_recentMetalBand);
      setState(() {});
    });
  }

  void initializeServices() {
    sps = Provider.of<SharedPreferencesService>(context, listen: false);
    _speciesList = sps?.speciesList ?? LocalSpeciesList();
  }

  Future<void> handleMap(Map<String, dynamic> map) async {
    if (map["route"] != null) {
      previousRouteName = map["route"];
    }
    if (map["nest"] != null) {
      nest = map["nest"] as Nest;
    }
    if (map["bird_id"] != null) {
      reloadBirdFromFirestore(map["bird_id"].toString());
    }

    if (map["bird"] != null) {
      //ageType is set within handleBird
      await handleBird(map);
    } else if (map["egg"] != null) {
      ageType = "chick";
      handleEgg(map);
    } else {
      //only nest this means ita a prent
      ageType = "parent";
      handleNoBirdNoEgg();
    }
    bird.addNonExistingExperiments(nest.experiments, ageType);
    bird.measures.sort();
    _species = _speciesList.getSpecies(bird.species);
   _recentMetalBand = sps?.getRecentMetalBand(bird.species ?? "") ?? "";
    nestnr.setValue(bird.nest);
    color_band.setValue(bird.color_band);
  }

  Future<void> handleBird(Map<String, dynamic> map) async {
    bird = map["bird"] as Bird;
    if (bird.band.isNotEmpty) {
      await reloadBirdFromFirestore(bird.band);
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
    bird.addMissingMeasures(allMeasures, ageType);
    //ensure that correct nests are referenced
    nests = widget.firestore.collection(bird.nest_year.toString());
  }

  Future<void> reloadBirdFromFirestore(String id) async {
    if(birds == null) return;
    bird = await birds!
        .doc(id)
        .get()
        .then((DocumentSnapshot value) => Bird.fromDocSnapshot(value)).catchError(onSnapshotError);
    ageType = bird.isChick() ? "chick" : "parent";
    bird.addNonExistingExperiments(nest.experiments, ageType);
  }

  Bird onSnapshotError(error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Error getting bird from firestore: $error"),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 5),
    ));
    Bird b = Bird(
      species: nest.species,
      ringed_date: DateTime.now(),
      ringed_as_chick: false,
      band: "",
      responsible: sps?.userName ?? "unknown",
      nest: nest.name,
      nest_year: nest.discover_date.year,
      measures: [],
      experiments: nest.experiments,
    );
    b.addMissingMeasures(allMeasures, b.getType());
    return b;
  }

  void updateBirdWithNestInfo() {
    bird.nest = nest.name;
    bird.nest_year = nest.discover_date.year;
    bird.species = nest.species;
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
      measures: [],
      experiments: nest.experiments,
    );
    bird.addMissingMeasures(allMeasures, "chick");
  }

  void handleNoBirdNoEgg() {
    bird = Bird(
      species: nest.species,
      ringed_date: DateTime.now(),
      ringed_as_chick: false,
      band: "",
      responsible: sps?.userName ?? "unknown",
      nest: nest.name,
      nest_year: nest.discover_date.year,
      measures: [],
      experiments: nest.experiments,
    );
    bird.addMissingMeasures(allMeasures, ageType);
  }

  void handleNoMap() {
    bird.measures = allMeasures;
    if (bird.ringed_as_chick) {
      bird.measures.removeWhere((element) => element.name == "age");
    }
    bird.measures.sort();
  }

  Row getMetalBandInput({bool hideNext = false}) {
    List<String> recentBand = guessNextMetalBand(_recentMetalBand);

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
        hideNext ? Container() : SizedBox(width: 10),
        hideNext
            ? Container()
            : ElevatedButton(
                onPressed: _recentMetalBand.isNotEmpty
                    ? () {
                  setState(() {
                    assignNextMetalBand(_recentMetalBand);
                  });
                }
              : null,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 1.0, vertical: 16.0),
            child: _recentMetalBand.isNotEmpty
                ? Text(recentBand.join())
                : Text("?????"),
          ),
        ),
      ],
    );
  }

  Row metalBand() {
    if(bird.id != null){
      //can't change band if it already exists
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: []);
    } else {
      return getMetalBandInput();
    }
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
    int ageYears = bird.ageInYears();
    int ageDays = bird.ageInDays();
    String age = ageYears > 0 ? "$ageYears years" : "$ageDays days";
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
              child: Text('Age: $age',
                  style: TextStyle(fontSize: 20, color: Colors.yellow))),
        ],
      ),
    );
  }

  Bird getBird() {
    String cb = color_band.valueCntr.text.toUpperCase();
    bird.nest = nestnr.valueCntr.text;
    bird.color_band = cb.isEmpty ? null : cb;
    if (bird.prevBird != null) {
      //the current nest year is changed now as well
      if (bird.nest != bird.prevBird!.nest) {
        bird.nest_year = DateTime.now().year;
      }
    }
    return bird;
  }

  changeMetalBand() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter dialogSetState) {
            return AlertDialog(
              backgroundColor: Colors.black,
              titleTextStyle:
                  TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              title: Text("Change ${bird.id}"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 10),
                  Text(
                      "Are you sure you want to change the metal band? Maybe you can just change the nest or delete the bird?  You can't overwrite existing bands"),
                  SizedBox(height: 20),
                  getMetalBandInput(hideNext: true),
                  SizedBox(height: 20),
                ],
              ),
            actions: [
              TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  onPressed: disableBandChangeButtons
                      ? null
                      : () {
                        Navigator.pop(context);
                      },
                child: Text("Cancel"),
              ),
              TextButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.redAccent),
                  ),
                  key: Key("changeBandButton"),
                  onPressed: disableBandChangeButtons
                      ? null
                      : () {
                          dialogSetState(() {
                            disableBandChangeButtons = true;
                          });
                          bird.band = (band_letCntr.text + band_numCntr.text)
                            .toUpperCase();
                        bird.responsible = sps?.userName ?? "unknown";
                        bird
                            .save(widget.firestore,
                                otherItems: nests, type: ageType)
                            .then((ur) {
                          if (ur.success) {
                            sps?.setRecentBand(bird.species ?? '', bird.band);
                              dialogSetState(() {
                                disableBandChangeButtons = false;
                              });
                              Navigator.pop(context);
                            deleteOk();
                          }
                          if (!ur.success) {
                              dialogSetState(() {
                                disableBandChangeButtons = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Can't change band: ${ur.message}"),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 5),
                            ));
                          }
                        });
                      },
                  child: disableBandChangeButtons
                      ? CircularProgressIndicator()
                      : Text("Change"),
              ),
            ],
            );
          });
        });
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
                  GestureDetector(
                    onLongPress: () {
                      changeMetalBand();
                    },
                    child: Column(children: [
                      Text("long press to edit band",
                          style: TextStyle(fontSize: 10, color: Colors.white)),
                      Text(bird.id != null ? "Metal: ${bird.id}" : "New bird",
                          style: TextStyle(fontSize: 20, color: Colors.yellow)),
                    ]),
                  ),
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
                  SizedBox(height: 10),
                  ModifyingButtons(firestore: widget.firestore, context:context,setState:setState, getItem:getBird, type:ageType, otherItems:nests,
                      silentOverwrite: false,
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
