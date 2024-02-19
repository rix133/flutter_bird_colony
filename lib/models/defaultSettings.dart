import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/firestoreItem.dart';
import 'package:kakrarahu/models/updateResult.dart';

import '../species.dart';

class DefaultSettings implements FirestoreItem{
  String? id;
  double desiredAccuracy;
  int selectedYear;
  bool autoNextBand;
  bool autoNextBandParent;
  GeoPoint defaultLocation;
  bool biasedRepeatedMeasurements;
  List<Species> species;
  Species defaultSpecies;

  @override
  String? responsible;


  DefaultSettings({
    this.id,
    required this.desiredAccuracy,
    required this.selectedYear,
    required this.autoNextBand,
    required this.autoNextBandParent,
    required this.defaultLocation,
    required this.biasedRepeatedMeasurements,
    required this.species,
    required this.defaultSpecies,
    this.responsible
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'desiredAccuracy': desiredAccuracy,
      'selectedYear': selectedYear,
      'autoNextBand': autoNextBand,
      'autoNextBandParent': autoNextBandParent,
      'defaultLocation': defaultLocation,
      'biasedRepeatedMeasurements': biasedRepeatedMeasurements,
      'species': species.map((e) => e.english).toList(),
      'defaultSpecies': defaultSpecies.english,
      'responsible': responsible ?? ''
    };
  }

  @override
  String get name => id ?? '';


  @override
  factory DefaultSettings.fromDocSnapshot(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    List<Species> species = <Species>[];
    for(String s in json['species']){
      species.add(SpeciesList.english.firstWhere((element) => element.english == s));
    }
    Species? defaultSpecies = SpeciesList.english.firstWhere((element) => element.english == json['defaultSpecies'], orElse: () => Species(english: '', local: '', latinCode: ''));
    return DefaultSettings(
      id: snapshot.id,
      desiredAccuracy: json['desiredAccuracy'],
      selectedYear: json['selectedYear'],
      autoNextBand: json['autoNextBand'],
      autoNextBandParent: json['autoNextBandParent'],
      defaultLocation: json['defaultLocation'],
      biasedRepeatedMeasurements: json['biasedRepeatedMeasurements'],
      species: species,
      defaultSpecies: defaultSpecies,
      responsible: json['responsible']
    );
  }

  @override
  Future<UpdateResult> save({CollectionReference<Object?>? otherItems = null, bool allowOverwrite = false, String type = "default"}) {
    if(id == null){
      id = "default";
    }
    return(FirebaseFirestore.instance.collection("settings").doc(id).set(toJson()).then((value) => UpdateResult.saveOK(item:this)).catchError((e) => UpdateResult.error(message: e.toString())));

  }


  @override
  Future<UpdateResult> delete({CollectionReference<Object?>? otherItems = null, bool soft = true, String type = "default"}) {
    return FirebaseFirestore.instance.collection("settings").doc(id).delete().then((value) => UpdateResult.deleteOK(item:this)).catchError((e) => UpdateResult.error(message: e.toString()));
  }



  @override
  List<TextCellValue> toExcelRowHeader() {

    throw UnimplementedError();
  }

  @override
  Future<List<List<CellValue>>> toExcelRows() {

    throw UnimplementedError();
  }

  List<Widget> getDefaultSettingsForm(BuildContext context, Function setState) {
    return (
        [
              TextFormField(
                initialValue: desiredAccuracy.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Desired accuracy (m)',
                  hintText: 'Desired accuracy (m)',
                ),
                onChanged: (value) {
                  desiredAccuracy = double.parse(value);
                  setState(() {});
                },
              ),
        Text('Selected year $selectedYear'),
        Slider(
        value: selectedYear.toDouble(),
    onChanged: (double value) {
    setState(() {
    selectedYear = value.toInt();
    });
    },
    min: DateTime.now().year.toDouble() - 2,
    max:  DateTime.now().year.toDouble() + 2,
    divisions: 5,
    label: selectedYear.toString(),
    ),
              SwitchListTile(
                title: const Text('Auto next band chick'),
                value: autoNextBand,
                onChanged: (bool value) {
                  autoNextBand = value;
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Auto next band parent'),
                value: autoNextBandParent,
                onChanged: (bool value) {
                  autoNextBandParent = value;
                  setState(() {});
                },
              ),
              TextFormField(
                initialValue: defaultLocation.latitude.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Default location latitude',
                  hintText: 'Default location latitude',
                ),
                onChanged: (value) {
                  defaultLocation =
                      GeoPoint(double.parse(value), defaultLocation.longitude);
                  setState(() {});
                },
              ),
              TextFormField(
                initialValue: defaultLocation.longitude.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Default location longitude',
                  hintText: 'Default location longitude',
                ),
                onChanged: (value) {
                  defaultLocation =
                      GeoPoint(defaultLocation.latitude, double.parse(value));
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Observer bias repeated measures'),
                value: biasedRepeatedMeasurements,
                onChanged: (bool value) {
                  biasedRepeatedMeasurements = value;
                  setState(() {});
                },
              ),
              DropdownButton<Species>(
                value: defaultSpecies,
                onChanged: (Species? newValue) {
                  defaultSpecies = newValue!;
                  setState(() {});
                },
                items: species.map<DropdownMenuItem<Species>>((Species value) {
                  return DropdownMenuItem<Species>(
                    value: value,
                    child: Text(value.english),
                  );
                }).toList(),
              ),
            ]);


  }
}