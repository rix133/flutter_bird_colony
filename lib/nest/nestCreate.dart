import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakrarahu/design/speciesRawAutocomplete.dart';
import 'package:kakrarahu/design/textFormItem.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/models/updateResult.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';
import '../models/nest.dart';
import '../models/species.dart';
import '../services/locationService.dart';

class NestCreate extends StatefulWidget {
  final FirebaseFirestore firestore;
  const NestCreate({super.key, required this.firestore});

  @override
  _NestCreateState createState() => _NestCreateState();
}

class _NestCreateState extends State<NestCreate> {
  CollectionReference? nests;
  DocumentReference? recent;
  SharedPreferencesService? sps;
  Stream<DocumentSnapshot> _idStream = Stream.empty();
  LocalSpeciesList _speciesList = LocalSpeciesList();
  bool _disableButtons = false;

  LocationService location = LocationService.instance;
  //AuthService auth = AuthService.instance;

  Nest nest = Nest(
    coordinates: GeoPoint(0, 0),
    accuracy: "loading...",
    last_modified: DateTime.now(),
    discover_date: DateTime.now(),
    responsible: null,
    measures: [Measure.note()],
  );


  void _getCurrentLocation() async {
    setState(() {
      _disableButtons = true;
    });
    final position = await location.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
      setState(() {
        //update only if the new location is more accurate
        if(nest.getAccuracy() > position.accuracy){
          nest.coordinates = GeoPoint(position.latitude, position.longitude);
          nest.accuracy = position.accuracy.toStringAsFixed(2) + "m";
        }
        _disableButtons = false;
      });
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nest.dispose();
    super.dispose();
  }

  @override
  void initState() {
    nests = widget.firestore.collection(DateTime.now().year.toString());
    recent = widget.firestore.collection('recent').doc("nest");
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var data = ModalRoute.of(context)?.settings.arguments;
      if (data != null) {
        nest = data as Nest;
      }
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      _speciesList = sps!.speciesList;
      nest.responsible = sps!.userName;
      //nest.species = sps!.defaultSpecies; //to set the default species automatically all the time
      _idStream = recent?.snapshots() ?? Stream.empty();
      setState(() {});
    });
  }

  Future<UpdateResult> _saveNewNest() {
    if (nest.id == null || nest.id == "") {
      return Future.value(UpdateResult.error(message: "Nest ID is empty"));
    }

    return nests!.doc(nest.id).get().then((value) {
      if (value.exists) {
        return UpdateResult.error(message: "Nest ${nest.id} already exists");
      } else {
        recent?.set({"id": nest.id});
        return (nest
            .save(widget.firestore)
            .then((value) => UpdateResult.saveOK(item: nest))
            .catchError(
                (error) => UpdateResult.error(message: error.toString())));
      }
    });
  }

  StreamBuilder _nextNestButton() {
    return StreamBuilder<DocumentSnapshot>(
        stream: _idStream,
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          Map<String, dynamic>? data = snapshot.data?.data() as Map<String, dynamic>?;

            int? next = int.tryParse(data?['id'] ?? "0");
            if (next != null) {
              next = next + 1;
              return ElevatedButton(
                onPressed: () {
                  setState(() {
                    nest.id = next.toString();
                  });
                },
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 20),
                    child: Text("Next: " + next.toString(), style: TextStyle(fontSize: 14))),
              );
            }

          return ElevatedButton(onPressed: null, child: Padding(padding: EdgeInsets.all(15), child: Text("No next")));
        });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.fromLTRB(10, 50, 10, 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Expanded(
                    child: TextFormItem(
                        label: 'enter nest ID',
                        initialValue: nest.id ?? "",
                        isNumber: true,
                        changeFun: (value) =>  nest.id = value)),
                SizedBox(width: 5),
                _nextNestButton(),
              ]),
              SpeciesRawAutocomplete(
                speciesList: _speciesList,
                species: _speciesList.getSpecies(nest.species),
                returnFun: (Species? value) {
                  if (value != null) {
                    setState(() {
                      nest.species = value.english;
                    });
                  }
                },
              ),
              SizedBox(height: 15),
              ...nest.measures.map((e) => e.getMeasureForm(
                  (Measure m) => setState(() => nest.measures.add(Measure.empty(e))),
                  true)),
              SizedBox(height: 15),
    Opacity(
    opacity: _disableButtons ? 0.3 : 1, // Dim the UI when loading
    child: AbsorbPointer(
    absorbing: _disableButtons, // Disable interaction when loading
    child:
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      new ElevatedButton.icon(
                          onPressed:  _getCurrentLocation,
                          icon: Icon(
                            Icons.my_location,
                            color: Colors.black87,
                            size: 40,
                          ),
                          label: Text("location")),
                      Text("Accuracy: " + nest.accuracy),
                    ],
                  ),
                  //Location accuracy
                  ElevatedButton.icon(
                      onPressed: () {
                        _disableButtons = true;
                        setState(() {});
                        _saveNewNest().then((value) {
                          if (value.success) {
                            Navigator.popAndPushNamed(context, '/nestManage',
                                arguments: {"nest": value.item});
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(value.message),
                                backgroundColor: Colors.red));
                            _disableButtons = false;
                            setState(() {});
                          }
                        });
                      },
                      icon: Icon(
                        Icons.save,
                        color: Colors.black87,
                        size: 45,
                      ),
                      label: Text("add nest")),
                ],
              ))),
            ],
          ),
        ),
      ),
    );
  }
}
