import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design//modifingButtons.dart';
import 'package:flutter_bird_colony/design/experimentDropdown.dart';
import 'package:flutter_bird_colony/design/speciesRawAutocomplete.dart';
import 'package:flutter_bird_colony/models/eggStatus.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/models/firestore/egg.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_bird_colony/services/locationService.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_bird_colony/utils/year.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'optionsNestImage.dart';

class EditNest extends StatefulWidget {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  const EditNest({super.key, required this.firestore, required this.storage});

  @override
  State<EditNest> createState() => _EditNestState();
}

class _EditNestState extends State<EditNest> {

  Species species = Species.empty();
  int new_egg_nr = 1;
  Position? position;
  List<Bird> parents = [];
  List<Egg?> eggs = [];
  LocalSpeciesList speciesList = LocalSpeciesList();
  double _desiredAccuracy = 1;
  Nest? nest;
  CollectionReference? nests;
  CollectionReference? eggCollection;
  Query? experimentsQuery;
  Stream<QuerySnapshot> _eggStream = Stream.empty();
  SharedPreferencesService? sps;
  LocationService location = LocationService.instance;
  //AuthService auth = AuthService.instance;

  var map = <String, dynamic>{};

  DateTime _dateTimeWithYear(DateTime base, int year) {
    return DateTime(year, base.month, base.day, base.hour, base.minute,
        base.second, base.millisecond, base.microsecond);
  }

  void addItem(value, String key) {
    if (value != null) {
      map.addEntries({key: value}.entries);
    }
  }

  @override
  void dispose() {
    if(nest != null){
      nest!.dispose();
    }
    super.dispose();
  }

  _updateControllers() {
    if(nest != null) {
      species = speciesList.getSpecies(nest!.species);
      nests = widget.firestore.collection(
          yearToNestCollectionName(nest!.discover_date.year));
      experimentsQuery = widget.firestore
          .collection("experiments")
          .where("year", isEqualTo: nest!.discover_date.year);
      if(nest!.id != null){
        eggCollection = nests?.doc(nest!.id).collection("egg");
      }
      _eggStream = eggCollection?.snapshots() ?? Stream.empty();
      position = Position(longitude: nest!.coordinates.longitude,
          latitude: nest!.coordinates.latitude,
          timestamp: nest!.discover_date,
          accuracy: nest!.getAccuracy(),
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0);
      nest!.addMissingMeasures(sps?.defaultMeasures, "nest");
      setState(() {   });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      _desiredAccuracy = sps?.desiredAccuracy ?? 4;
      var data = ModalRoute.of(context)?.settings.arguments as Map;
      speciesList = sps?.speciesList ?? LocalSpeciesList();
      final selectedYear = sps?.selectedYear ?? DateTime.now().year;
      nests = widget.firestore.collection(yearToNestCollectionName(selectedYear));
      experimentsQuery = widget.firestore
          .collection("experiments")
          .where("year", isEqualTo: selectedYear);
      if (data["year"] != null) {
        nests = widget.firestore
            .collection(nestCollectionNameFromYearOrName(data["year"]));
        final year = int.tryParse(data["year"].toString());
        if (year != null) {
          experimentsQuery = widget.firestore
              .collection("experiments")
              .where("year", isEqualTo: year);
        }
      }
      if(data["nest_id"] != null) {
        nests?.doc(data["nest_id"]).get().then((value) {
          if (value.exists) {
              nest = Nest.fromDocSnapshot(value);
              _updateControllers();
          }
        });
      }
      if(data["nest"] != null){
        nest = data["nest"] as Nest;
        _updateControllers();
      }

    });
  }

  Widget locationButton(){
    if(nest == null || position == null){
      return SizedBox.shrink();
    }
    double accuracyDiff = (position?.accuracy ?? 999999) - _desiredAccuracy;
    Future<void> updateFun() async {
      position = await location.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      if((position?.accuracy ?? 999999) < nest!.getAccuracy()){
        nest!.coordinates = GeoPoint(position!.latitude, position!.longitude);
        nest!.setAccuracy(position!.accuracy);
      }
      setState(() { });
    };
    return (Padding(
      padding: const EdgeInsets.all(8.0),
      child:
        ElevatedButton.icon(
        style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(
                    accuracyDiff < 0 ? Colors.green : Colors.red)),
            onPressed: () => updateFun(),
        icon: Icon(
          Icons.my_location,
          color: Colors.black87,
          size: 40,
        ),
        label: Padding(padding:EdgeInsets.symmetric(vertical: 20),
        child:Text('~${position!.accuracy.toStringAsFixed(1)}m')))
    ));
  }

  List<Egg> getEggs() {
    return eggs.map((e) => e!).toList();
  }

  Nest getNest() {
    if (nest != null) {
      nest!.species = species.english;
      nest!.responsible = sps?.userName;
      return nest!;
    }
    throw Exception("Nest is not initialized");
  }

  StreamBuilder _getEggsStream(Stream<QuerySnapshot> _eggStream) {
    Egg egg;
    return (StreamBuilder<QuerySnapshot>(
      stream: _eggStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasData) {
          eggs = snapshot.data!.docs.map((doc) {
            egg = Egg.fromDocSnapshot(doc);
            egg.addNonExistingExperiments(nest!.experiments, "egg");
            if (nest!.first_egg == null) {
              nest!.first_egg = egg.discover_date;
            }
            return egg.knownOrder() ? egg : null;
          }).toList();
          //filter out nulls
          eggs.removeWhere((element) => element == null);
          return Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...eggs.map((egg) {
                  return egg!.knownOrder()
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      egg.getButton(context, nest),
                      SizedBox(height: 5),
                    ],
                  ) : SizedBox.shrink();
                }).toList(),
                ..._getAddEggButton(context, snapshot),
              ],
            ),
          );
        }

        return SizedBox.shrink(); // Return an empty widget if there's no data
      },
    ));
  }

  List<Widget> _getAddEggButton(
      BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData) {
      return [Text('No data')];
    }
    List<Egg> eggs = snapshot.data!.docs.map((e) => Egg.fromDocSnapshot(e)).toList();
    int amount = eggs
        .where((e) =>
            e.ring != null && e.discover_date.year == nest?.discover_date.year)
        .length;
    int new_egg_nr = eggs.where((e) => e.type() == "egg").length + 1;
    final nestYear = nest?.discover_date.year ?? DateTime.now().year;
    final discoverDate = _dateTimeWithYear(DateTime.now(), nestYear);

    return [
      Text(
        "Ringed ($amount)",
        style: TextStyle(fontSize: 10),
      ),
      ElevatedButton.icon(
          style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.grey)),
          onPressed: () {
              Egg egg = Egg(
                  discover_date: discoverDate,
                responsible: sps?.userName,
                measures: [],
                  experiments: nest?.experiments ?? [],
                  last_modified: DateTime.now(),
                status: EggStatus("intact"),
                ring: null);
              if (new_egg_nr == 1) {
                nest!.first_egg = discoverDate;
              }
              String eggID = nest!.name + " egg " + new_egg_nr.toString();
              eggCollection?.doc(eggID)
                  .set(egg.toJson())
                  .whenComplete(() => eggCollection?.doc(eggID)
                      .collection("changelog")
                      .doc(DateTime.now().toString())
                      .set(egg.toJson()));

          },
          icon: Icon(
            Icons.egg,
            size: 45,
          ),
          onLongPress: () {
            Navigator.pushNamed(context, "/editBird", arguments: {
              "nest": nest,
              "route": '/editNest',
              //this egg has no number as it has no id
              "egg": Egg(
                  discover_date: discoverDate,
                  last_modified: DateTime.now(),
                  responsible: sps?.userName,
                  measures: [],
                  experiments: nest?.experiments ?? [],
                  status: EggStatus("unknown"),
                  ring: null),
            });
          },
          label: Column(
            children: [
              Text("add egg"),
              Text(
                "(long press for chick)",
                style: TextStyle(fontSize: 10),
              )
            ],
          )),
      SizedBox(height: 15),
    ];
  }
  _addNewExperiment() async {
    String? selectedExperiment;
    List<String> existingExperiments = nest!.experiments?.map((e) => e.name).toList() ?? [];
    experimentsQuery?.get().then((value) {
      List<Experiment> exps = value.docs
          .map((DocumentSnapshot e) => Experiment.fromDocSnapshot(e))
          .where((Experiment e) => existingExperiments.contains(e.name) == false)
          .toList();
      showDialog(context: context, builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add new experiment"),
          backgroundColor: Colors.black87,
          content: ExperimentDropdown(
            allExperiments: exps,
            selectedExperiment: selectedExperiment,
            onChanged: (String? e) {
              selectedExperiment = e;
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel", style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () {
                if(selectedExperiment != null){
                  Experiment exp = exps.firstWhere((element) => element.name == selectedExperiment);
                  if(exp.nests == null){
                    exp.nests = [];
                  }
                  exp.nests!.add(nest!.name);
                  exp.save(widget.firestore).then((v) =>
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/editNest', ModalRoute.withName('/findNest'),
                          arguments: {
                            "nest_id": nest!.name,
                            "year": nest!.discover_date.year,
                          })
                  );
                }
              },
              child: Text("Add", style: TextStyle(color: Colors.red)),
            ),],
        );
      });
    });
  }

  void addParent() {
    Navigator.pushNamed(context, "/editBird", arguments: {
      "nest": nest,
      "route": '/editNest',
    });
  }

  Widget _getParentsRow(List<Bird>? _parents, BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
          height: 50.0, // Adjust this value as needed
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...?_parents?.map((Bird b) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/editBird", arguments: {
                      "bird": b,
                      "nest": nest,
                      "route": '/editNest',
                    });
                  },
                  child: Text(b.name),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.white60),
                  ),
                );
              }).toList(),
              (_parents?.length == 0 || _parents == null)
                  ? ElevatedButton.icon(
                      style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all(_getParentButtonColor())),
                      onPressed: addParent,
                      icon: Icon(Icons.add),
                      label: Text("add parent"))
                  : IconButton(
                      icon: Icon(Icons.add),
                      onPressed: addParent,
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all<Color>(Colors.white60),
                      ),
                    ),
            ],
          )),
    );
  }

  void addMeasure(Measure m) {
    if(nest != null){
      setState(() {
        nest!.measures.add(m);
        nest!.measures.sort();
      });
    }

  }


  Color _getParentButtonColor() {
    if (_daysSinceFirstEgg() > 10) {
      return Colors.white60;
    }
    return Colors.grey;
  }

  int _daysSinceFirstEgg() {
    return DateTime.now().difference(nest!.first_egg ?? DateTime.now()).inDays;
  }

  GestureDetector getTitleRow() {
    return GestureDetector(
      onLongPress: _addNewExperiment,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            padding: EdgeInsets.all(5),
            iconSize: 40,
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              if (nest != null && nests != null) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: NestImageOptions(
                        nestDoc: nests!.doc(nest!.name),
                        firestore: widget.firestore,
                        storage: widget.storage,
                      ),
                    );
                  },
                );
              }
            },
          ),
          const SizedBox(width: 5),
          Text(
            nest!.name,
            style: const TextStyle(fontSize: 30, fontStyle: FontStyle.italic),
          ),
          const SizedBox(width: 5),
          Column(
            children: [
              Text(
                nest!.checkedStr(),
                style: TextStyle(
                  fontSize: 14.0,
                  color: nest!.chekedAgo().inDays == 0
                      ? Colors.green
                      : Colors.yellow.shade700,
                ),
              ),
              const Text("(long press to add experiment)",
                  style: TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    if (nest == null) {
      // Return a CircularProgressIndicator while nest is loading
      return Scaffold(
          appBar: (sps?.showAppBar ?? true)
              ? AppBar(
                  title: Text('Edit Nest'),
                )
              : null,
          body: SafeArea(
            child: Center(
              child: Container(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[CircularProgressIndicator()],
            ),
          ),
        ),
          ));
    }

    return Scaffold(
        appBar: (sps?.showAppBar ?? true)
            ? AppBar(
                title: Text('Edit Nest'),
              )
            : null,
        body: SafeArea(
          child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                getTitleRow(),
                listExperiments(nest!), //list of experiments
                SizedBox(height: 15),
                Row(children:[Expanded(child:SpeciesRawAutocomplete(
                  speciesList: speciesList,
                  species: species,
                  returnFun: (Species s) {
                    setState(() {
                      species = speciesList.getSpecies(s.english);
                    });
                  },
                )),
                  locationButton(),]),
                SizedBox(height: 15),
                ...nest!.measures
                    .map((Measure m) => m.getMeasureForm(
                            addMeasure, sps?.biasedRepeatedMeasures ?? false))
                        .toList(),
                SizedBox(height: 15),
                _getParentsRow(nest!.parents, context),
                _getEggsStream(_eggStream),
                SizedBox(height: 30),
                ModifyingButtons(
                    firestore: widget.firestore,
                    context: context,
                    setState: setState,
                    getItem: getNest,
                    type: "modify",
                    otherItems: null,
                    silentOverwrite: true,
                    getOtherItems: getEggs),
              ],
            ),
          ))),
        ));
  }
}
