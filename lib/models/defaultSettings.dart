import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/firestoreItem.dart';
import 'package:kakrarahu/models/firestoreItemMixin.dart';
import 'package:kakrarahu/models/speciesRawAutocomplete.dart';
import 'package:kakrarahu/models/updateResult.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';

import 'species.dart';

class DefaultSettings implements FirestoreItem {
  String? id;
  double desiredAccuracy;
  int selectedYear;
  bool autoNextBand;
  bool autoNextBandParent;
  GeoPoint defaultLocation;
  bool biasedRepeatedMeasurements;
  String settingsType = "default";
  Species defaultSpecies;

  @override
  String? responsible;

  DefaultSettings(
      {this.id,
      required this.desiredAccuracy,
      required this.selectedYear,
      required this.autoNextBand,
      required this.autoNextBandParent,
      required this.defaultLocation,
      required this.biasedRepeatedMeasurements,
      required this.settingsType,
      required this.defaultSpecies,
      this.responsible});

  @override
  Map<String, dynamic> toJson() {
    return {
      'desiredAccuracy': desiredAccuracy,
      'selectedYear': selectedYear,
      'autoNextBand': autoNextBand,
      'autoNextBandParent': autoNextBandParent,
      'defaultLocation': defaultLocation,
      'biasedRepeatedMeasurements': biasedRepeatedMeasurements,
      'defaultSpecies': defaultSpecies.toJson(),
      'responsible': responsible ?? ''
    };
  }

  @override
  String get name => id ?? '';

  @override
  factory DefaultSettings.fromDocSnapshot(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    Species? defaultSpecies = json['defaultSpecies'] == null
        ? Species(english: '', local: '', latinCode: '')
        : Species.fromJson(json['defaultSpecies']);
    return DefaultSettings(
        id: snapshot.id,
        desiredAccuracy: json['desiredAccuracy'],
        selectedYear: json['selectedYear'],
        autoNextBand: json['autoNextBand'],
        autoNextBandParent: json['autoNextBandParent'],
        defaultLocation: json['defaultLocation'],
        biasedRepeatedMeasurements: json['biasedRepeatedMeasurements'],
        settingsType: snapshot.id,
        defaultSpecies: defaultSpecies,
        responsible: json['responsible']);
  }

  @override
  Future<UpdateResult> save(
      {CollectionReference<Object?>? otherItems = null,
      bool allowOverwrite = false,
      String type = "default"}) {
    if (id == null) {
      id = type;
    }
    return (FirebaseFirestore.instance
        .collection("settings")
        .doc(id)
        .set(toJson())
        .then((value) => UpdateResult.saveOK(item: this))
        .catchError((e) => UpdateResult.error(message: e.toString())));
  }

  @override
  Future<UpdateResult> delete(
      {CollectionReference<Object?>? otherItems = null,
      bool soft = true,
      String type = "default"}) {
    if (id == null) {
      return Future.value(UpdateResult.deleteOK(item: this));
    }
    return (FSItemMixin().deleteFiresoreItem(
        this,
        FirebaseFirestore.instance.collection('settings'),
        FirebaseFirestore.instance
            .collection('settings')
            .doc(type)
            .collection("deletedSettings")));
  }

  @override
  List<TextCellValue> toExcelRowHeader() {
    throw UnimplementedError();
  }

  @override
  Future<List<List<CellValue>>> toExcelRows() {
    throw UnimplementedError();
  }

  List<Widget> getDefaultSettingsForm(
      BuildContext context, Function setState, SharedPreferencesService? sps) {
    return ([
      SizedBox(height: 10),
      SpeciesRawAutocomplete(
          returnFun: (Species s) {
            defaultSpecies = s;
            setState(() {});
          },
          species: defaultSpecies,
          speciesList: sps?.defaultSpeciesList ?? [],
          borderColor: Colors.white38,
          bgColor: Colors.amberAccent,
          labelTxt: 'Default species',
          labelColor: Colors.grey),
      SizedBox(height: 10),
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
      SizedBox(height: 10),
      Text('Selected year $selectedYear'),
      Slider(
        value: selectedYear.toDouble(),
        onChanged: (double value) {
          setState(() {
            selectedYear = value.toInt();
          });
        },
        min: DateTime.now().year.toDouble() - 2,
        max: DateTime.now().year.toDouble() + 2,
        divisions: 5,
        label: selectedYear.toString(),
      ),
      SizedBox(height: 10),
      SwitchListTile(
        title: const Text('Auto next band chick'),
        value: autoNextBand,
        onChanged: (bool value) {
          autoNextBand = value;
          setState(() {});
        },
      ),
      SizedBox(height: 10),
      SwitchListTile(
        title: const Text('Auto next band parent'),
        value: autoNextBandParent,
        onChanged: (bool value) {
          autoNextBandParent = value;
          setState(() {});
        },
      ),
      SizedBox(height: 10),
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
      SizedBox(height: 10),
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
      SizedBox(height: 10),
      SwitchListTile(
        title: const Text('Observer bias repeated measures'),
        value: biasedRepeatedMeasurements,
        onChanged: (bool value) {
          biasedRepeatedMeasurements = value;
          setState(() {});
          setState(() {});
        },
      ),
    ]);
  }
}
